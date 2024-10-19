import type { Submission } from "../submissions/submissions.ts";

export default function SongSubmission(
  { submission, index, totalItems }: {
    submission: Submission;
    index: number;
    totalItems: number;
  },
) {
  const move = async (direction: "up" | "down") => {
    await fetch("/api/submissions", {
      method: "POST",
      body: JSON.stringify({ direction, index }),
    });

    globalThis.location.reload();
  };

  const remove = async () => {
    await fetch("/api/submissions", {
      method: "DELETE",
      body: JSON.stringify({ index }),
    });

    globalThis.location.reload();
  };

  return (
    <div class="p-4 m-4 bg-rose-400 text-white flex">
      <div class="flex-1">
        <div>{submission.name}</div>
        <div>{submission.song}</div>
      </div>
      <div class="flex-initial flex flex-col justify-between">
        {index != 0
          ? (
            <svg
              class="cursor-pointer w-4 h-4"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 384 512"
              onClick={() => move("up")}
            >
              <path d="M214.6 41.4c-12.5-12.5-32.8-12.5-45.3 0l-160 160c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0L160 141.2 160 448c0 17.7 14.3 32 32 32s32-14.3 32-32l0-306.7L329.4 246.6c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3l-160-160z" />
            </svg>
          )
          : <div></div>}
        {index != totalItems - 1
          ? (
            <svg
              class="cursor-pointer w-4 h-4"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 384 512"
              onClick={() => move("down")}
            >
              <path d="M169.4 470.6c12.5 12.5 32.8 12.5 45.3 0l160-160c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0L224 370.8 224 64c0-17.7-14.3-32-32-32s-32 14.3-32 32l0 306.7L54.6 265.4c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3l160 160z" />
            </svg>
          )
          : <div></div>}
        <svg
          class="cursor-pointer w-4 h-4"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 384 512"
          onClick={() => remove()}
        >
          <path d="M376.6 84.5c11.3-13.6 9.5-33.8-4.1-45.1s-33.8-9.5-45.1 4.1L192 206 56.6 43.5C45.3 29.9 25.1 28.1 11.5 39.4S-3.9 70.9 7.4 84.5L150.3 256 7.4 427.5c-11.3 13.6-9.5 33.8 4.1 45.1s33.8 9.5 45.1-4.1L192 306 327.4 468.5c11.3 13.6 31.5 15.4 45.1 4.1s15.4-31.5 4.1-45.1L233.7 256 376.6 84.5z" />
        </svg>
      </div>
    </div>
  );
}
