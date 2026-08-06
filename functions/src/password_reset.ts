import { getAuth } from "firebase-admin/auth";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

const region = "asia-southeast1";
const firebaseWebApiKey = defineSecret("FIREBASE_WEB_API_KEY");

const PROJECT_ID = "dembee-auction";
const CONTINUE_URL = `https://${PROJECT_ID}.firebaseapp.com/reset-password`;
const ANDROID_PACKAGE = "com.dembee.auction";

async function sendPasswordResetEmail(email: string, apiKey: string) {
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        requestType: "PASSWORD_RESET",
        email,
        continueUrl: CONTINUE_URL,
        canHandleCodeInApp: true,
        androidInstallApp: true,
        androidPackageName: ANDROID_PACKAGE,
        androidMinimumVersion: "1",
      }),
    },
  );

  const body = (await response.json()) as {
    error?: { message?: string; status?: string };
  };

  if (!response.ok) {
    const status = body.error?.status ?? "";
    logger.error("sendOobCode алдаа", { status, email });

    if (status === "EMAIL_NOT_FOUND") {
      throw new HttpsError("not-found", "Энэ имэйлээр бүртгэл олдсонгүй");
    }
    if (status === "INVALID_EMAIL") {
      throw new HttpsError("invalid-argument", "Имэйл буруу байна");
    }

    throw new HttpsError(
      "internal",
      "Нууц үг сэргээх имэйл илгээхэд алдаа гарлаа",
    );
  }
}

/** Бүртгэлтэй имэйлд нууц үг сэргээх холбоос илгээнэ (апп руу чиглүүлнэ) */
export const requestPasswordReset = onCall(
  { region, secrets: [firebaseWebApiKey] },
  async (request) => {
    const email = (request.data?.email as string | undefined)?.trim();
    if (!email) {
      throw new HttpsError("invalid-argument", "И-мэйл хаягаа оруулна уу");
    }

    const auth = getAuth();
    try {
      await auth.getUserByEmail(email);
    } catch (error: unknown) {
      const code =
        error && typeof error === "object" && "code" in error
          ? String((error as { code?: string }).code)
          : "";

      if (code === "auth/user-not-found") {
        throw new HttpsError(
          "not-found",
          "Энэ имэйлээр бүртгэл олдсонгүй",
        );
      }

      throw new HttpsError(
        "internal",
        "Имэйл шалгахад алдаа гарлаа. Дахин оролдоно уу.",
      );
    }

    const apiKey = firebaseWebApiKey.value()?.trim();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Firebase API түлхүүр тохируулагдаагүй. Админ firebase functions:secrets:set FIREBASE_WEB_API_KEY ажиллуулна уу",
      );
    }

    await sendPasswordResetEmail(email, apiKey);
    return { ok: true };
  },
);

/** @deprecated requestPasswordReset ашиглана */
export const verifyEmailForPasswordReset = requestPasswordReset;
