-- Seed demo data for Banking App

-- Use a transaction for seed to ensure atomicity
BEGIN;

-- Insert demo user if not exists
INSERT INTO public.users (email, password_hash)
SELECT 'demo@bank.local', '$2b$12$PLACEHOLDER_HASH_REPLACE_IN_PROD'
WHERE NOT EXISTS (
    SELECT 1 FROM public.users WHERE email = 'demo@bank.local'
);

-- Get demo user id
WITH demo_user AS (
    SELECT id FROM public.users WHERE email = 'demo@bank.local' LIMIT 1
)
-- Insert accounts if none exist for demo user
INSERT INTO public.accounts (user_id, name, currency, balance)
SELECT du.id, a.name, a.currency, a.balance
FROM demo_user du
CROSS JOIN (
    VALUES
      ('Checking Account', 'USD', 1250.00),
      ('Savings Account', 'USD', 5000.00)
) AS a(name, currency, balance)
WHERE NOT EXISTS (
    SELECT 1 FROM public.accounts WHERE user_id = (SELECT id FROM demo_user)
);

-- Insert some transactions for the first account
DO $$
DECLARE
  acct1 INT;
  acct2 INT;
BEGIN
  SELECT a1.id, a2.id INTO acct1, acct2
  FROM (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) rn
    FROM public.accounts a
    JOIN public.users u ON a.user_id = u.id
    WHERE u.email = 'demo@bank.local'
  ) t1
  LEFT JOIN (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) rn
    FROM public.accounts a
    JOIN public.users u ON a.user_id = u.id
    WHERE u.email = 'demo@bank.local'
  ) t2 ON t2.rn = 2
  WHERE t1.rn = 1;

  -- Only seed if we have at least one account and there are no transactions yet
  IF acct1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.transactions WHERE account_id = acct1) THEN
    INSERT INTO public.transactions (account_id, type, amount, currency, description, created_at)
    VALUES
      (acct1, 'deposit', 1000.00, 'USD', 'Initial deposit', NOW() - INTERVAL '10 days'),
      (acct1, 'withdrawal', 200.00, 'USD', 'ATM cash withdrawal', NOW() - INTERVAL '7 days'),
      (acct1, 'deposit', 450.50, 'USD', 'Paycheck deposit', NOW() - INTERVAL '3 days');

    -- Transfer from Checking to Savings if both exist and no prior transfer
    IF acct2 IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.transactions WHERE type = 'transfer' AND account_id IN (acct1, acct2)
    ) THEN
      INSERT INTO public.transactions (account_id, type, amount, currency, description, related_account_id, created_at)
      VALUES
        (acct1, 'transfer', 150.00, 'USD', 'Transfer to savings', acct2, NOW() - INTERVAL '1 day');
      INSERT INTO public.transactions (account_id, type, amount, currency, description, related_account_id, created_at)
      VALUES
        (acct2, 'transfer', 150.00, 'USD', 'Transfer from checking', acct1, NOW() - INTERVAL '1 day');
    END IF;
  END IF;
END $$;

COMMIT;
