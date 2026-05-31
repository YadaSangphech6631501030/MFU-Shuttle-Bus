const express = require("express");
const router = express.Router();

const { getDB } = require("../db");

router.get("/:line", async (req, res) => {
  try {
    const line = req.params.line;

    const db = getDB();
    const col = db.collection("stations");

    const data = await col.find({
      lines: line
    }).toArray();

   const updatedStations = data.map((s) => {
    let waiting = s.waiting ?? 0;

  let status = "LOW";
  if (waiting >= 10) status = "HIGH";
  else if (waiting >= 5) status = "MEDIUM";

  let eta = Math.floor(Math.random() * 6) + 3;

  return { ...s, waiting, status, eta };
});

    res.json(updatedStations);

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "server error" });
  }
});

module.exports = router;