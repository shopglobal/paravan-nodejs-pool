UPDATE pool.config SET item_value = 'support@etnxpool.com' WHERE module = 'general' and item = 'adminEmail';
UPDATE pool.config SET item_value = 'notification@mail.etnxpool.com' WHERE module = 'general' and item = 'emailFrom';
UPDATE pool.config SET item_value = 'YOUR_POOL_ADDRESS_HERE' WHERE module = 'pool' and item = 'address';
UPDATE pool.config SET item_value = 'YOUR_FEE_ADDRESS_HERE' WHERE module = 'payout' and item = 'feeAddress';
UPDATE pool.config SET item_value = 'key-xxxxxxxx' WHERE module = 'general' and item = 'mailgunKey';
UPDATE pool.config SET item_value = 'https://api.mailgun.net/v3/xxxxxxx' WHERE module = 'general' and item = 'mailgunURL';
UPDATE pool.config SET item_value = 'https://etnxpool.com/leafApi' WHERE module = 'general' and item = 'shareHost';
UPDATE pool.config SET item_value = 'Https://etnxpool.com' WHERE module = 'general' and item = 'emailSig';