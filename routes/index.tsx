import { Handlers } from "$fresh/server.ts";
import { submissionQueue } from "../submissions/submissions.ts";

export const handler: Handlers = {
  async GET(req, ctx) {
    const params = new URL(req.url).searchParams;
    return await ctx.render({
      message: params.get("flash"),
    });
  },

  async POST(req, _ctx) {
    const form = await req.formData();
    const name = form.get("name")?.toString();
    const song = form.get("song")?.toString();

    if (!name || !song) {
      return new Response(null, {
        status: 400,
      });
    }

    submissionQueue.addSubmission({ name, song });

    const headers = new Headers();
    const message = `Alright, ${name}, you're signed up to sing ${song}`;
    headers.set("location", `/?flash=${encodeURIComponent(message)}`);
    return new Response(null, {
      status: 303,
      headers,
    });
  },
};

export default function Home({ data }: { data: { message: string } }) {
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
        {data.message && (
          <p class="p-4 mb-4 bg-rose-400 text-white">{data.message}</p>
        )}
        <h1 class="text-4xl font-bold">Let's Karaoke!</h1>
        <form method="post">
          <label class="block mb-4">
            Name:
            <input class="block p-2" type="text" name="name" value="" />
          </label>

          <label class="block mb-4">
            Song &amp; Artist:
            <input class="block p-2" type="text" name="song" value="" />
          </label>

          <button
            type="submit"
            class="bg-rose-400 w-full p-4 rounded-md text-white"
          >
            Submit
          </button>
        </form>
      </div>
    </div>
  );
}
