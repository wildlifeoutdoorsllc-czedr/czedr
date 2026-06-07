<?php
declare(strict_types=1);

namespace Czedr\Mail;

use Czedr\Support\Env;

/** Sends transactional email via SMTP (MAIL_* in .env). */
final class MailService
{
    public function isConfigured(): bool
    {
        if (Env::get('MAIL_ENABLED', '0') !== '1') {
            return false;
        }
        $host = trim((string) (Env::get('MAIL_HOST') ?? ''));
        $from = trim((string) (Env::get('MAIL_FROM') ?? ''));

        return $host !== '' && $from !== '' && filter_var($from, FILTER_VALIDATE_EMAIL);
    }

    public function send(string $to, string $subject, string $bodyText, ?string $bodyHtml = null): void
    {
        if (!$this->isConfigured()) {
            throw new \RuntimeException('Email is not configured (set MAIL_ENABLED=1 and MAIL_* in .env)');
        }
        if (!filter_var($to, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException('Invalid recipient email');
        }

        $from = (string) Env::get('MAIL_FROM');
        $fromName = trim((string) (Env::get('MAIL_FROM_NAME', 'CZEDR') ?? 'CZEDR'));
        $host = (string) Env::get('MAIL_HOST');
        $port = (int) (Env::get('MAIL_PORT', '587') ?? 587);
        $user = (string) (Env::get('MAIL_USER', '') ?? '');
        $pass = (string) (Env::get('MAIL_PASS', '') ?? '');
        $encryption = strtolower(trim((string) (Env::get('MAIL_ENCRYPTION', 'tls') ?? 'tls')));

        $boundary = 'czedr_' . bin2hex(random_bytes(8));
        $headers = $this->buildHeaders($from, $fromName, $to, $subject, $boundary, $bodyHtml !== null);
        $body = $bodyHtml !== null
            ? $this->multipartBody($boundary, $bodyText, $bodyHtml)
            : $this->encodeBody($bodyText);

        $this->smtpSend($host, $port, $encryption, $user, $pass, $from, [$to], $headers, $body);
    }

  private function buildHeaders(
        string $from,
        string $fromName,
        string $to,
        string $subject,
        string $boundary,
        bool $multipart,
    ): string {
        $encodedSubject = '=?UTF-8?B?' . base64_encode($subject) . '?=';
        $fromHeader = $fromName !== ''
            ? sprintf('=?UTF-8?B?%s?= <%s>', base64_encode($fromName), $from)
            : $from;

        $lines = [
            'Date: ' . gmdate('D, d M Y H:i:s') . ' +0000',
            'From: ' . $fromHeader,
            'To: ' . $to,
            'Subject: ' . $encodedSubject,
            'MIME-Version: 1.0',
        ];
        $replyTo = trim((string) (Env::get('MAIL_SUPPORT', 'support@czedr.com') ?? 'support@czedr.com'));
        if ($replyTo !== '' && filter_var($replyTo, FILTER_VALIDATE_EMAIL)) {
            $lines[] = 'Reply-To: ' . $replyTo;
        }
        if ($multipart) {
            $lines[] = 'Content-Type: multipart/alternative; boundary="' . $boundary . '"';
        } else {
            $lines[] = 'Content-Type: text/plain; charset=UTF-8';
            $lines[] = 'Content-Transfer-Encoding: base64';
        }

        return implode("\r\n", $lines);
    }

    private function encodeBody(string $text): string
    {
        return chunk_split(base64_encode($text), 76, "\r\n");
    }

    private function multipartBody(string $boundary, string $text, string $html): string
    {
        $out = "--{$boundary}\r\n";
        $out .= "Content-Type: text/plain; charset=UTF-8\r\n";
        $out .= "Content-Transfer-Encoding: base64\r\n\r\n";
        $out .= $this->encodeBody($text) . "\r\n";
        $out .= "--{$boundary}\r\n";
        $out .= "Content-Type: text/html; charset=UTF-8\r\n";
        $out .= "Content-Transfer-Encoding: base64\r\n\r\n";
        $out .= $this->encodeBody($html) . "\r\n";
        $out .= "--{$boundary}--\r\n";

        return $out;
    }

    /** @param list<string> $recipients */
    private function smtpSend(
        string $host,
        int $port,
        string $encryption,
        string $user,
        string $pass,
        string $from,
        array $recipients,
        string $headers,
        string $body,
    ): void {
        $remote = $encryption === 'ssl' ? "ssl://{$host}:{$port}" : "tcp://{$host}:{$port}";
        $fp = @stream_socket_client($remote, $errno, $errstr, 30, STREAM_CLIENT_CONNECT);
        if (!$fp) {
            throw new \RuntimeException("SMTP connect failed: {$errstr} ({$errno})");
        }
        stream_set_timeout($fp, 30);

        try {
            $this->expect($fp, [220]);
            $this->cmd($fp, 'EHLO czedr.com');
            $ehlo = $this->readMultiline($fp);
            if ($encryption === 'tls') {
                if (!str_contains($ehlo, 'STARTTLS')) {
                    throw new \RuntimeException('SMTP server does not support STARTTLS');
                }
                $this->cmd($fp, 'STARTTLS');
                $this->expect($fp, [220]);
                if (!stream_socket_enable_crypto($fp, true, STREAM_CRYPTO_METHOD_TLS_CLIENT)) {
                    throw new \RuntimeException('SMTP STARTTLS failed');
                }
                $this->cmd($fp, 'EHLO czedr.com');
                $this->readMultiline($fp);
            }
            if ($user !== '') {
                $this->cmd($fp, 'AUTH LOGIN');
                $this->expect($fp, [334]);
                $this->cmd($fp, base64_encode($user));
                $this->expect($fp, [334]);
                $this->cmd($fp, base64_encode($pass));
                $this->expect($fp, [235]);
            }
            $this->cmd($fp, 'MAIL FROM:<' . $from . '>');
            $this->expect($fp, [250]);
            foreach ($recipients as $rcpt) {
                $this->cmd($fp, 'RCPT TO:<' . $rcpt . '>');
                $this->expect($fp, [250, 251]);
            }
            $this->cmd($fp, 'DATA');
            $this->expect($fp, [354]);
            fwrite($fp, $headers . "\r\n\r\n" . $body . "\r\n.\r\n");
            $this->expect($fp, [250]);
            $this->cmd($fp, 'QUIT');
        } finally {
            fclose($fp);
        }
    }

    private function cmd($fp, string $line): void
    {
        fwrite($fp, $line . "\r\n");
    }

    /** @param list<int> $codes */
    private function expect($fp, array $codes): void
    {
        $line = $this->readLine($fp);
        $code = (int) substr($line, 0, 3);
        if (!in_array($code, $codes, true)) {
            throw new \RuntimeException('SMTP error: ' . trim($line));
        }
    }

    private function readLine($fp): string
    {
        $line = fgets($fp, 8192);
        if ($line === false) {
            throw new \RuntimeException('SMTP connection closed');
        }

        return $line;
    }

    private function readMultiline($fp): string
    {
        $buf = '';
        do {
            $line = $this->readLine($fp);
            $buf .= $line;
        } while (isset($line[3]) && $line[3] === '-');

        return $buf;
    }
}
