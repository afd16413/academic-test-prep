-- Run once in the Supabase SQL Editor, after the earlier SQL files.
-- Lets guests take tests without an account. A guest gives only a nickname, which is saved with the answers.

-- 1. Guests (visitors who are not signed in) can list and open tests.
create policy "guests can read tests"
  on public.tests for select
  to anon
  using (true);

-- 2. Guest answers have no account, so user_id may be empty. Then a nickname is required.
alter table public.submissions alter column user_id drop not null;

alter table public.submissions
  add column if not exists guest_name text;

alter table public.submissions drop constraint if exists submissions_owner_check;
alter table public.submissions
  add constraint submissions_owner_check
  check (user_id is not null or (guest_name is not null and char_length(trim(guest_name)) between 1 and 40));

-- 3. Guests may add reading, listening and writing answers with no account.
--    Speaking recordings are not included: they are stored in a private bucket that needs an account.
create policy "guests add nicknamed submissions"
  on public.submissions for insert
  to anon
  with check (user_id is null and guest_name is not null and kind in ('reading', 'listening', 'writing'));

-- Admins already read all submissions (supabase-listening-writing-speaking.sql), so teachers see guest nicknames.
