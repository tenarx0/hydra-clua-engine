-- ==============================================================================
-- TABLE: crypto
-- C++ Backend: Libsodium (NaCl) primitives. Memory zeroed via `sodium_memzero`.
-- ==============================================================================

-- crypto.hash(data_string)
-- C++: `crypto_generichash` (BLAKE2b).
-- Returns: (string) 32-byte raw binary hash.

-- crypto.sha256(data_string)
-- C++: `crypto_hash_sha256`.
-- Returns: (string) 32-byte raw binary hash.

-- crypto.encrypt(message_string, key_string)
-- C++: `crypto_secretbox_easy` (XSalsa20-Poly1305). Generates a random 24-byte nonce.
-- Constraints: `key_string` MUST be exactly 32 bytes or throws luaL_error.
-- Returns: (string) Concatenated payload: [24-byte Nonce] + [Ciphertext + MAC].

-- crypto.decrypt(payload_string, key_string)
-- C++: `crypto_secretbox_open_easy`. Automatically extracts the 24-byte nonce from the head.
-- Constraints: `key_string` MUST be exactly 32 bytes. `payload_string` must be >= 40 bytes.
-- Returns: (string | nil, err) The plaintext string, or nil + error if MAC verification fails.

-- crypto.hmac(message_string, key_string)
-- C++: `crypto_auth_hmacsha256`.
-- Constraints: `key_string` MUST be exactly 32 bytes.
-- Returns: (string) 32-byte raw binary HMAC.

-- crypto.randomBytes(size_int)
-- C++: `randombytes_buf`. Allocates secure entropy.
-- Constraints: `size_int` must be 1 to 65536. Default is 32.
-- Returns: (string) Raw binary string of secure random bytes.

-- crypto.deriveKey(password_string, salt_string)
-- C++: `crypto_pwhash` (Argon2id13, interactive limits).
-- Constraints: `salt_string` MUST be exactly 16 bytes (`crypto_pwhash_SALTBYTES`).
-- Returns: (string) 32-byte raw binary key suitable for `crypto.encrypt`.

-- crypto.randomInt(min_int, max_int)
-- C++: `randombytes_uniform(range)`. Unbiased secure integer generation.
-- Returns: (integer) Value between min and max (inclusive).

-- crypto.randomFloat()
-- C++: `randombytes_random() / 0xffffffff`.
-- Returns: (number) Unbiased float between 0.0 and 1.0.

-- crypto.signKeyPair()
-- C++: `crypto_sign_keypair` (Ed25519).
-- Returns: (string, string) 32-byte Public Key, 64-byte Secret Key.

-- crypto.sign(message_string, secret_key_string)
-- C++: `crypto_sign`. Prepends the mathematical signature to the payload.
-- Constraints: `secret_key_string` MUST be exactly 64 bytes.
-- Returns: (string) 64-byte Signature + Message.

-- crypto.verify(signed_payload_string, public_key_string)
-- C++: `crypto_sign_open`. Verifies the Ed25519 signature and strips it.
-- Constraints: `public_key_string` MUST be exactly 32 bytes.
-- Returns: (string | nil) The original message, or nil if forged/corrupted.

-- crypto.dhKeyPair()
-- C++: `crypto_scalarmult_base` (X25519).
-- Returns: (string, string) 32-byte Public Key, 32-byte Secret Key.

-- crypto.dhDerive(their_public_key, my_secret_key)
-- C++: `crypto_scalarmult`. Derives a shared secret.
-- Constraints: Both keys MUST be exactly 32 bytes. Throws error on suspicious public key.
-- Returns: (string) 32-byte shared AES-ready secret.

-- crypto.hashPassword(password_string)
-- C++: `crypto_pwhash_str`. Automatically handles salt generation and formats output.
-- Returns: (string) Argon2id modular crypt format string (e.g., "$argon2id$v=19...").

-- crypto.verifyPassword(hash_string, password_string)
-- C++: `crypto_pwhash_str_verify`. Constant-time verification.
-- Returns: (boolean) true if the password matches the hash.


-- 1. Key Derivation & Hashing
local password = "user_secure_password"
local salt = crypto.randomBytes(16) -- Always exactly 16 bytes for Argon2id
local aes_key = crypto.deriveKey(password, salt) -- 32-byte key

-- Secure password storage (generates a DB-ready Argon2id string)
local db_hash = crypto.hashPassword(password)
local is_valid = crypto.verifyPassword(db_hash, password)

-- 2. Authenticated Encryption (XSalsa20-Poly1305)
local secret_payload = "MISSION_CRITICAL_DATA"
local encrypted_blob = crypto.encrypt(secret_payload, aes_key)

-- Decryption (Automatically verifies MAC, returns nil on tampering)
local plaintext, err = crypto.decrypt(encrypted_blob, aes_key)
if not plaintext then
    print("Decryption failed or payload tampered: " .. err)
end

-- 3. Digital Signatures (Ed25519)
local pub_key, sec_key = crypto.signKeyPair()
local signed_message = crypto.sign("Server Command: EXECUTE", sec_key)

local verified_msg = crypto.verify(signed_message, pub_key)
if verified_msg then
    print("Signature authentic. Executing: " .. verified_msg)
end

-- 4. Diffie-Hellman Key Exchange (Curve25519)
local my_pub, my_sec = crypto.dhKeyPair()
-- Receive their_pub over network...
-- local shared_secret = crypto.dhDerive(their_pub, my_sec)