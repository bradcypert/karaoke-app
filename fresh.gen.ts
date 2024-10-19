// DO NOT EDIT. This file is generated by Fresh.
// This file SHOULD be checked into source version control.
// This file is automatically updated during development when running `dev.ts`.

import * as $_404 from "./routes/_404.tsx";
import * as $_app from "./routes/_app.tsx";
import * as $admin from "./routes/admin.tsx";
import * as $api_submissions from "./routes/api/submissions.ts";
import * as $index from "./routes/index.tsx";
import * as $song_submission from "./islands/song-submission.tsx";
import type { Manifest } from "$fresh/server.ts";

const manifest = {
  routes: {
    "./routes/_404.tsx": $_404,
    "./routes/_app.tsx": $_app,
    "./routes/admin.tsx": $admin,
    "./routes/api/submissions.ts": $api_submissions,
    "./routes/index.tsx": $index,
  },
  islands: {
    "./islands/song-submission.tsx": $song_submission,
  },
  baseUrl: import.meta.url,
} satisfies Manifest;

export default manifest;
