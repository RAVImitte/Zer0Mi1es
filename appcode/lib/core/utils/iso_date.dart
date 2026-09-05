String isoDate([DateTime? date]) =>
    (date ?? DateTime.now()).toIso8601String().split('T').first;
