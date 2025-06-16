// functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const express = require("express");
const cors = require("cors");

// Express app
const app = express();

// Middlewares
app.use(cors({ origin: true }));
app.use(express.json()); // ✅ this is important for parsing JSON

// Initialize Firebase Admin SDK
admin.initializeApp();

// ====== Gmail credentials via environment config ======
// You must set these with: 
//   firebase functions:config:set gmail.email="your_email@gmail.com" gmail.password="your_app_password"
// Make sure app password has no spaces; copy exactly the 16-character string from Google.
const gmailEmail = functions.config().gmail.email;
const gmailAppPassword = functions.config().gmail.password;

// Validate that config is present
if (!gmailEmail || !gmailAppPassword) {
  console.error("Gmail credentials are not set in functions config. " +
    "Run: firebase functions:config:set gmail.email=\"your_email@gmail.com\" gmail.password=\"your_app_password\"");
}

// Create Nodemailer transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: gmailEmail,
    pass: gmailAppPassword,
  },
});

// sendOtpEmail: callable function to send OTP via email
// Expects data: { email: string, otp: string }
exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
  // Basic validation
  const email = data.email;
  const otp = data.otp;

  if (typeof email !== "string" || typeof otp !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with arguments { email: string, otp: string }."
    );
  }

  // Mail options
  const mailOptions = {
    from: `iPlate App <${gmailEmail}>`,
    to: email,
    subject: "Your iPlate OTP Code",
    text: `Hello,\n\nYour OTP code is: ${otp}\n\nIf you did not request this, please ignore.\n\nThanks,\niPlate Team`,
    // You can also send HTML if you like:
    // html: `<p>Hello,</p><p>Your OTP code is: <strong>${otp}</strong></p><p>If you did not request this, please ignore.</p><p>Thanks,<br/>iPlate Team</p>`
  };

  try {
    // Send email
    const info = await transporter.sendMail(mailOptions);
    console.log("sendOtpEmail: Email sent", info.response);
    return { success: true };
  } catch (error) {
    console.error("sendOtpEmail: Error sending email:", error);
    // Throw an HttpsError so client receives an error
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send OTP email."
    );
  }
});

// ====== Express route for sending OTP via email ======
// This is an alternative to the callable function, using Express
// Route to send OTP
app.post("/", (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return res.status(400).send("Missing email or OTP.");
  }

  const mailOptions = {
    from: `iPlate App <${gmailEmail}>`,
    to: email,
    subject: "Your iPlate OTP Code",
    text: `Your OTP is: ${otp}`,
  };

  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      console.error("Error sending email:", error);
      return res.status(500).send("Failed to send email.");
    }
    return res.status(200).send("OTP sent successfully.");
  });
});

// Export the HTTPS function
exports.sendOtpEmail = functions.https.onRequest(app);

//cd functions
// npx firebase emulators:start --only functions
/*
curl -X POST http://127.0.0.1:5001/iplate/us-central1/sendOtpEmail \
  -H "Content-Type: application/json" \
  -d '{"email": "kriarora1211@gmail.com", "otp": "123456"}'
*/
