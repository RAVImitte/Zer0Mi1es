import urllib.request, json
data = json.loads(urllib.request.urlopen('https://api.github.com/repos/RAVImitte/Zer0Mi1es/issues?state=open').read())
for i in data:
    print(f"Issue #{i['number']}: {i['title']}")
    print(f"Body: {i['body']}\n")
