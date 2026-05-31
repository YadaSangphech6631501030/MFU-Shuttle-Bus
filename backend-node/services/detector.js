const { spawn } = require("child_process");
const { CAMERA_URL } = require("../config");

function runDetector() {
  const process = spawn("python3", ["python/detector.py", CAMERA_URL]);

  process.stdout.on("data", (data) => {
    console.log(`YOLO: ${data}`);
  });

  process.stderr.on("data", (data) => {
    console.error(`YOLO ERROR: ${data}`);
  });
}

module.exports = { runDetector };