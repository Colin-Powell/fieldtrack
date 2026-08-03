import nodemailer from 'nodemailer';

class EmailService {
  private transporter: nodemailer.Transporter;

  constructor() {
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;

    if (!smtpUser || !smtpPass) {
      throw new Error('SMTP credentials must be configured via environment variables.');
    }

    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
    });
  }

  async sendEmail(to: string, subject: string, html: string, text?: string): Promise<void> {
    const mailOptions: nodemailer.SendMailOptions = {
      from: `"FieldTrack Support" <${process.env.SMTP_USER}>`,
      to,
      subject,
      html,
      text: text ?? html.replaceAll(new RegExp('<[^>]*>', 'g'), ''),
    };

    try {
      await this.transporter.sendMail(mailOptions);
    } catch (error) {
      console.error('Error sending email:', error);
      throw new Error('Failed to send email');
    }
  }

  async sendPasswordResetOtp(to: string, otp: string): Promise<void> {
    const mailOptions = {
      from: `"FieldTrack Support" <${process.env.SMTP_USER}>`,
      to,
      subject: 'FieldTrack - Password Reset OTP',
      text: `Your password reset OTP is: ${otp}. It will expire in 10 minutes.`,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
          <h2 style="color: #16A34A;">FieldTrack Password Reset</h2>
          <p>You requested a password reset. Please use the following OTP to reset your password:</p>
          <div style="font-size: 24px; font-weight: bold; padding: 10px; background-color: #f4f4f4; border-radius: 8px; display: inline-block;">
            ${otp}
          </div>
          <p>This OTP is valid for 10 minutes.</p>
          <p>If you did not request this, please ignore this email.</p>
        </div>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
    } catch (error) {
      console.error('Error sending email:', error);
      throw new Error('Failed to send OTP email');
    }
  }
}

export const emailService = new EmailService();
