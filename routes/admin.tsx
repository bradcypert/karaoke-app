import { Handlers } from "$fresh/server.ts";
import SongSubmission from "../islands/song-submission.tsx";
import {
  type Submission,
  submissionQueue,
} from "../submissions/submissions.ts";

export const handler: Handlers = {
  async GET(_req, ctx) {
    return await ctx.render({
      submissions: submissionQueue.submissions,
    });
  },
};

export default function AdminInterface(
  { data }: { data: { submissions: Array<Submission> } },
) {
  return (
    <div class="px-4 py-8 mx-auto bg-[#86efac] h-screen">
      <div class="max-w-screen-md mx-auto flex flex-col items-center justify-center">
        <img
          class="my-6"
          src="/logo.svg"
          width="128"
          height="128"
          alt="the Fresh logo: a sliced lemon dripping with juice"
        />
        <h1 class="text-4xl font-bold">Admin Interface!</h1>
        {data.submissions.map((submission, index) => {
          return (
            <SongSubmission
              submission={submission}
              index={index}
              totalItems={data.submissions.length}
            />
          );
        })}
      </div>
    </div>
  );
}
