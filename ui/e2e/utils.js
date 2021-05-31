// utils.js
import StreamZip from "node-stream-zip";
import axios from "axios";
import fs from "fs";
import path from "path";
import mkdirp from "mkdirp";
const { saveVideo } = require("playwright-video");

// Not in use, don't have good place to get the extension zips, for now
export async function downloadFile(name, url, dir) {
  const write = path.resolve(dir, `${name}.zip`);
  const writer = fs.createWriteStream(write);

  const response = await axios({
    url,
    method: "GET",
    responseType: "stream",
  });

  response.data.pipe(writer);

  return new Promise((resolve, reject) => {
    writer.on("finish", resolve);
    writer.on("error", reject);
  });
}

export async function extractFile(downloadedFile, extractDestination) {
  const zip = new StreamZip.async({ file: downloadedFile });
  if (!fs.existsSync(extractDestination)) {
    fs.mkdirSync(extractDestination);
  }
  await zip.extract(null, extractDestination);
}

export async function getExtensionPage(browserContext, extensionId) {
  return new Promise((resolve, reject) => {
    browserContext.waitForEvent("page", async (page) => {
      if (page.url().match(`chrome-extension://${extensionId}`)) {
        try {
          resolve(page);
        } catch (e) {
          reject(e);
        }
      }
    });
  });
}

export function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function recordVideo(page, name) {
  const date = new Date();
  const year = date.getFullYear();
  const month = date.getUTCMonth() + 1;
  const dateOfMonth = date.getUTCDate();
  const hour = date.getUTCHours();
  const minute = date.getUTCMinutes();
  const sec = date.getUTCSeconds();
  const dateString = `${year}-${month}-${dateOfMonth}-${hour}-${minute}-${sec}`;

  const videoPath = `videos/chromium-${dateString}-${name.replace(
    / /g,
    "_",
  )}.mp4`;

  await mkdirp("videos");
  await saveVideo(page, videoPath);
}
