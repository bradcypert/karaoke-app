/// Server-rendered HTML shells. Lustre apps mount into #app.
/// All interactive logic lives in the compiled JS.

pub fn public_page() -> String {
  "<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
  <title>Karaoke Queue — Submit a Song</title>
  <link rel=\"stylesheet\" href=\"/static/styles.css\" />
</head>
<body>
  <div id=\"app\"></div>
  <script type=\"module\" src=\"/static/app.mjs\"></script>
</body>
</html>"
}

pub fn admin_page() -> String {
  "<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
  <title>Karaoke Queue — Admin</title>
  <link rel=\"stylesheet\" href=\"/static/styles.css\" />
</head>
<body>
  <div id=\"app\"></div>
  <script type=\"module\" src=\"/static/admin.mjs\"></script>
</body>
</html>"
}
