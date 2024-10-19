import { submissionQueue } from "../../submissions/submissions.ts";
import { Handlers } from "$fresh/server.ts";

export const handler: Handlers = {
  async POST(req: Request) {
    const body: { direction: "up" | "down"; index: number } = await req.json();
    await submissionQueue.moveSubmission(body.index, body.direction);

    return new Response(null, {
      status: 200,
    });
  },
  async DELETE(req: Request) {
    const body: { index: number } = await req.json();
    await submissionQueue.removeSubmission(body.index);

    return new Response(null, {
      status: 200,
    });
  },
};
