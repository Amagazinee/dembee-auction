import { getAuth } from "firebase-admin/auth";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const region = "asia-southeast1";

/** Бүртгэлтэй имэйл эсэхийг шалгана — нууц үг сэргээхийн өмнө */
export const verifyEmailForPasswordReset = onCall(
  { region },
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

    return { ok: true };
  },
);
