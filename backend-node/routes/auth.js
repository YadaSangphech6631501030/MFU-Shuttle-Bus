const express = require("express");
const router = express.Router();
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const { connectDB, getDB } = require("../db");

const { SECRET_KEY } = require("../config");
const tokenRequired = require("../middleware/jwt");
const adminOnly = require("../middleware/admin");

// ================= REGISTER =================
router.post("/register", async (req, res) => {
  console.log("🔥 HIT REGISTER");
  console.log(req.body);

  try {
    const { username, password, email } = req.body;

    if (!username || !password || !email) {
      return res.status(400).json({ error: "All fields required" });
    }

    const db = getDB();
    const users = db.collection("users");

    const existingUser = await users.findOne({ username });
    if (existingUser) {
      return res.status(400).json({ error: "Username exists" });
    }

    const hashed = await bcrypt.hash(password, 10);

    await users.insertOne({
      username,
      email,
      password: hashed,
      role: "user"
    });

    return res.json({ message: "User created" });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
});

// ================= LOGIN =================
router.post("/login", async (req, res) => {
  try {
    const { username, password } = req.body;

    const db = getDB();
    const users = db.collection("users");

    const user = await users.findOne({ username });

    if (!user) {
      return res.status(401).json({ error: "Invalid login" });
    }

    const match = await bcrypt.compare(password, user.password);

    if (!match) {
      return res.status(401).json({ error: "Invalid login" });
    }

    const token = jwt.sign(
      { 
        id: user._id,
        username: user.username,
        role: user.role
       },
      SECRET_KEY,
      { expiresIn: "2h" }
    );

    res.json({ 
      token,
      role: user.role,
      userId: user._id
     });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
});

// ================= GET USER (🔥 ตัวที่คุณขาด) =================
router.get("/user", tokenRequired, async (req, res) => {
  try {
    const db = getDB();
    const users = db.collection("users");

    const user = await users.findOne({
      username: req.user.username
    });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({
      username: user.username,
      email: user.email
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
});

// ================= UPDATE PROFILE =================
router.put("/update", tokenRequired, async (req, res) => {
  try {
    const { username, email, password, new_password } = req.body;

    const db = getDB();
    const users = db.collection("users");

    const user = await users.findOne({
      username: req.user.username
    });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const match = await bcrypt.compare(password, user.password);

    if (!match) {
      return res.status(401).json({ error: "Wrong password" });
    }

    let updatedData = {
      username,
      email
    };

    if (new_password && new_password !== "") {
      const hashed = await bcrypt.hash(new_password, 10);
      updatedData.password = hashed;
    }

    await users.updateOne(
      { username: req.user.username },
      { $set: updatedData }
    );

    res.json({ message: "Profile updated" });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
});

// admin
router.get("/admin/users", tokenRequired, adminOnly, async (req, res) => {
  try {
    const db = getDB();
    const users = db.collection("users");

    const allUsers = await users.find().toArray();

    res.json(allUsers);
  } catch (err) {
    res.status(500).json({ error: "Server error" });
  }
});

//delete only admin
router.delete("/admin/user/:username", tokenRequired, adminOnly, async (req, res) => {
  const db = getDB();
  const users = db.collection("users");

  await users.deleteOne({ username: req.params.username });

  res.json({ message: "User deleted" });
});

module.exports = router;