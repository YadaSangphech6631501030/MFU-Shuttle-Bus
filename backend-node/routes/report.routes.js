const express = require("express");
const router = express.Router();
const { getDB } = require("../db");
const { ObjectId } = require("mongodb");

// =========================
// 📤 CREATE REPORT
// =========================
router.post("/report", async (req, res) => {
  try {
    const db = getDB();

    const { type, detail, location, UserId } = req.body;

    const newReport = {
      type,
      detail,
      location,
      status: "pending",

      UserId: new ObjectId(UserId),

      time: new Date(),
    };

    await db.collection("reports").insertOne(newReport);

    res.status(201).json(newReport);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// =========================
// 📥 GET ALL REPORTS
// =========================
router.get("/report", async (req, res) => {
  try {
    const db = getDB();

    const reports = await db
      .collection("reports")
      .aggregate([
        {
          $lookup: {
            from: "users",
            localField: "UserId",
            foreignField: "_id",
            as: "user",
          },
        },
        {
          $unwind: {
            path: "$user",
            preserveNullAndEmptyArrays: true,
          },
        },
        {
          $sort: { time: -1 },
        },
      ])
      .toArray();

    res.json(reports);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// =========================
// ✏️ UPDATE REPORT STATUS
// =========================
router.put("/report/:id", async (req, res) => {
  try {
    const db = getDB();

    const id = req.params.id;
    const { status } = req.body;

    console.log("🔥 ID:", id);
    console.log("🔥 STATUS:", status);

    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ error: "Invalid ID format" });
    }

    const result = await db.collection("reports").updateOne(
      { _id: new ObjectId(id) },
      { $set: { status } }
    );

    console.log("🔥 RESULT:", result);

    if (result.matchedCount === 0) {
      return res.status(404).json({ error: "Report not found" });
    }

    res.json({ message: "updated" });

  } catch (err) {
    console.log("❌ ERROR:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;