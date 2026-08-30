import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { JWT } from 'npm:google-auth-library@9'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Parse the payload from the Database Webhook
    const payload = await req.json()
    console.log('Webhook payload:', payload)

    const record = payload.record
    let receiverId = null
    let title = 'Zer0Mi1es'
    let body = 'You have a new notification.'

    let senderId = null;
    if (payload.table === 'love_drops') senderId = record.sender_id;
    else if (['connection_signals', 'moods', 'daily_answers', 'daily_photos', 'daily_outfits'].includes(payload.table)) {
      senderId = record.user_id;
    }

    let senderName = 'Your partner';
    if (senderId) {
      const { data: profile } = await supabase.from('profiles').select('display_name').eq('id', senderId).single();
      if (profile && profile.display_name) {
        senderName = profile.display_name;
      }
    }

    // Determine event type based on table name
    if (payload.table === 'love_drops') {
      receiverId = record.couple_id // We need to find the partner
      const dropType = record.type || 'Love Drop';
      const msg = record.message;

      const emojiMap: Record<string, string> = {
        'Kiss': '💋',
        'Hug': '🤗',
        'Heart': '💖',
        'Sorry': '🥺'
      };
      
      const emoji = emojiMap[dropType] || dropType;

      if (msg) {
        title = `"${emoji}" ${senderName} says...`;
        body = `"${msg}"`;
      } else {
        title = `Love Drop ${emoji}`
        body = `${senderName} sent you a ${dropType}!`
      }
    } else if (payload.table === 'connection_signals') {
      receiverId = record.couple_id // We need to find the partner
      const signalType = record.type || record.signal_type || 'signal';
      
      if (signalType === 'text') {
        title = 'I Want to Talk 💬';
        body = `${senderName} wants you to text them.`;
      } else if (signalType === 'call') {
        title = 'Incoming Request 📞';
        body = `${senderName} wants to hear your voice.`;
      } else if (signalType === 'video_call') {
        title = 'Video Call Request 📹';
        body = `${senderName} wants to see your face.`;
      } else if (signalType === 'goodNight') {
        title = 'Sweet Dreams 🌙';
        body = `${senderName} is going to sleep.`;
      } else if (signalType === 'goodMorning') {
        title = 'Rise and Shine ☀️';
        body = `${senderName} has woken up.`;
      } else if (signalType === 'nudge') {
        title = 'Daily Question Reminder ⏰';
        body = `${senderName} is waiting for you to answer today's question!`;
      } else {
        title = 'Partner Signal';
        body = `${senderName} needs affection.`;
      }
    } else if (payload.table === 'daily_answers') {
      receiverId = record.couple_id;
      if (record.answer && record.answer.length > 0) {
        title = `${senderName} answered today's question! 📝`;
        body = `Tap to see what they said and send some love! 💖`;
      } else if (record.guess && record.guess.length > 0) {
        title = `${senderName} guessed your answer! 🎯`;
        body = `Open the app to see if they got it right!`;
      } else {
        title = `${senderName} updated their response! 📝`;
        body = `Tap to check it out! 💖`;
      }
    } else if (payload.table === 'daily_photos') {
      receiverId = record.couple_id;
      title = `${senderName} shared a new photo! 📸`;
      body = `Don't leave them waiting, go see their update! 👀`;
    } else if (payload.table === 'daily_outfits') {
      receiverId = record.couple_id;
      title = `${senderName} got dressed for the day! 👕`;
      body = `Check out their outfit and match their vibe! ✨`;
    } else {
      receiverId = payload.receiver_id
      title = payload.title || title
      body = payload.body || body
    }

    if (!receiverId) {
      return new Response(JSON.stringify({ error: 'No receiver found' }), { status: 400 })
    }

    // Get the FCM token for the receiver
    let actualReceiverId = receiverId
    if (['love_drops', 'connection_signals', 'daily_answers', 'daily_photos', 'daily_outfits'].includes(payload.table)) {
      const { data: couple, error: coupleErr } = await supabase.from('couples').select('bear_id, bunny_id').eq('id', receiverId).single()
      if (coupleErr) console.error('Couple lookup error:', coupleErr)

      if (couple) {
        const sid = record.sender_id || record.user_id;
        actualReceiverId = (couple.bear_id === sid) ? couple.bunny_id : couple.bear_id
        console.log(`Resolved actualReceiverId: ${actualReceiverId}`)
      }
    }

    const { data: profile, error: profileErr } = await supabase.from('profiles').select('fcm_token').eq('id', actualReceiverId).single()
    if (profileErr) console.error('Profile lookup error:', profileErr)

    const fcmToken = profile?.fcm_token

    if (!fcmToken) {
      console.log(`No FCM token found for user ${actualReceiverId}. Exiting early.`)
      return new Response(JSON.stringify({ message: 'User has no FCM token' }), { headers: corsHeaders })
    }

    console.log(`Found FCM token for ${actualReceiverId}: ${fcmToken.substring(0, 15)}...`)

    // --- Firebase HTTP v1 API Integration ---
    // 1. Get the Service Account JSON string from Supabase Secrets
    const serviceAccountJsonStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountJsonStr) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT secret is missing')
    }

    const serviceAccount = JSON.parse(serviceAccountJsonStr)
    const projectId = serviceAccount.project_id

    // 2. Generate an OAuth2 token using google-auth-library
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })

    const tokens = await jwtClient.authorize()
    const accessToken = tokens.access_token

    if (!accessToken) {
      throw new Error('Failed to generate access token from service account')
    }

    // 3. Send the notification via HTTP v1 API
    const fcmResponse = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: title,
            body: body,
          },
          data: {
            table: payload.table || '',
            type: (payload.table === 'love_drops' || payload.table === 'connection_signals') ? (record.type || '') : (payload.table === 'moods' ? (record.mood || '') : ''),
          }
        }
      })
    })

    const fcmResult = await fcmResponse.json()
    console.log('FCM Result:', fcmResult)

    return new Response(JSON.stringify({ success: true, fcmResult }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
