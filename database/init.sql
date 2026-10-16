CREATE TABLE IF NOT EXISTS public.records (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title varchar(200) NOT NULL CHECK (length(trim(title)) > 0)
);
