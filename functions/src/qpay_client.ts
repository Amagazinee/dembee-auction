import { logger } from "firebase-functions";

export interface QPayConfig {
  baseUrl: string;
  username: string;
  password: string;
  invoiceCode: string;
  callbackUrl: string;
}

export interface QPayBankLink {
  name: string;
  description: string;
  logo: string;
  link: string;
}

export interface QPayInvoiceResult {
  invoiceId: string;
  qrText: string;
  qrImage: string;
  shortUrl: string;
  urls: QPayBankLink[];
}

interface TokenResponse {
  access_token: string;
  expires_in: number;
}

interface InvoiceResponse {
  invoice_id: string;
  qr_text: string;
  qr_image: string;
  qPay_shortUrl?: string;
  qpay_shortUrl?: string;
  urls?: QPayBankLink[];
}

interface PaymentCheckResponse {
  count: number;
  paid_amount?: number;
}

let cachedToken: { value: string; expiresAt: number } | null = null;

export function loadQPayConfig(): QPayConfig {
  const baseUrl =
    process.env.QPAY_BASE_URL?.trim() || "https://merchant.qpay.mn";
  const username = process.env.QPAY_USERNAME?.trim() || "";
  const password = process.env.QPAY_PASSWORD?.trim() || "";
  const invoiceCode = process.env.QPAY_INVOICE_CODE?.trim() || "";
  const callbackUrl = process.env.QPAY_CALLBACK_URL?.trim() || "";

  if (!username || !password || !invoiceCode || !callbackUrl) {
    throw new Error("QPay тохиргоо дутуу байна");
  }

  return { baseUrl, username, password, invoiceCode, callbackUrl };
}

async function getAccessToken(config: QPayConfig): Promise<string> {
  const now = Date.now();
  if (cachedToken && cachedToken.expiresAt > now + 60_000) {
    return cachedToken.value;
  }

  const auth = Buffer.from(`${config.username}:${config.password}`).toString(
    "base64",
  );

  const response = await fetch(`${config.baseUrl}/v2/auth/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/json",
    },
  });

  if (!response.ok) {
    const body = await response.text();
    logger.error("QPay token алдаа", { status: response.status, body });
    throw new Error("QPay token авахад алдаа гарлаа");
  }

  const data = (await response.json()) as TokenResponse;
  cachedToken = {
    value: data.access_token,
    expiresAt: now + data.expires_in * 1000,
  };
  return data.access_token;
}

export async function createSimpleInvoice(params: {
  config: QPayConfig;
  senderInvoiceNo: string;
  description: string;
  amount: number;
}): Promise<QPayInvoiceResult> {
  const token = await getAccessToken(params.config);

  const response = await fetch(`${params.config.baseUrl}/v2/invoice`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      invoice_code: params.config.invoiceCode,
      sender_invoice_no: params.senderInvoiceNo,
      invoice_receiver_code: "terminal",
      invoice_description: params.description,
      amount: params.amount,
      callback_url: params.config.callbackUrl,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    logger.error("QPay invoice алдаа", { status: response.status, body });
    throw new Error("QPay invoice үүсгэхэд алдаа гарлаа");
  }

  const data = (await response.json()) as InvoiceResponse;
  return {
    invoiceId: data.invoice_id,
    qrText: data.qr_text,
    qrImage: data.qr_image,
    shortUrl: data.qPay_shortUrl || data.qpay_shortUrl || "",
    urls: data.urls || [],
  };
}

export async function hasPaidInvoice(
  config: QPayConfig,
  invoiceId: string,
): Promise<boolean> {
  const token = await getAccessToken(config);

  const response = await fetch(`${config.baseUrl}/v2/payment/check`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      object_type: "INVOICE",
      object_id: invoiceId,
      offset: {
        page_number: 1,
        page_limit: 10,
      },
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    logger.error("QPay payment check алдаа", {
      status: response.status,
      body,
      invoiceId,
    });
    throw new Error("QPay төлбөр шалгахад алдаа гарлаа");
  }

  const data = (await response.json()) as PaymentCheckResponse;
  return (data.count ?? 0) > 0;
}
