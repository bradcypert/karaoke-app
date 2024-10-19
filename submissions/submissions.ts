import { Mutex } from "https://deno.land/x/async@v2.1.0/mod.ts";

export interface Submission {
  name: string;
  song: string;
}

class SubmissionQueue {
  submissions: Array<Submission> = [];
  smutex = new Mutex();

  async addSubmission(submission: Submission) {
    await this.smutex.acquire();
    this.submissions.push(submission);
    this.smutex.release();
  }

  async moveSubmission(index: number, direction: "up" | "down") {
    await this.smutex.acquire();
    const swapIndex = direction == "down" ? index + 1 : index - 1;
    if (
      (index >= 0 && index < this.submissions.length) &&
      (swapIndex >= 0 && swapIndex <= this.submissions.length)
    ) {
      const temp = this.submissions[index];
      this.submissions[index] = this.submissions[swapIndex];
      this.submissions[swapIndex] = temp;
    }

    this.smutex.release();
  }

  async removeSubmission(index: number) {
    await this.smutex.acquire();
    if (index >= 0 && index < this.submissions.length) {
      this.submissions.splice(index, 1);
    }

    this.smutex.release();
  }
}

export const submissionQueue = new SubmissionQueue();
