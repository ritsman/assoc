DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'synetra_user') THEN
    CREATE ROLE synetra_user LOGIN PASSWORD 'synetra_password';
  END IF;
END $$;
