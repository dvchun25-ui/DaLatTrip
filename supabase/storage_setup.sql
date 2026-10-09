-- DALATTRIP uses Supabase for Storage only. Run this once in Supabase SQL Editor.
-- Firebase Auth must be enabled under Authentication > Third-Party Auth first.
-- Firebase tokens without a custom role run as `anon`, so policies explicitly
-- accept both database roles but still require this Firebase project issuer,
-- audience, UID folder, and a non-empty subject.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 3145728, array['image/jpeg', 'image/png', 'image/webp']),
  ('checkins', 'checkins', true, 20971520, array['image/jpeg', 'video/mp4']),
  ('community', 'community', true, 20971520, array['image/jpeg', 'video/mp4']),
  ('chat-media', 'chat-media', true, 20971520, array['image/jpeg', 'video/mp4'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Cần SELECT cho thao tác upsert avatar. Public bucket vẫn chỉ cho tải file
-- qua public URL; policy này giới hạn việc đọc metadata/list vào thư mục UID.
drop policy if exists "dalattrip firebase users select own media" on storage.objects;
create policy "dalattrip firebase users select own media"
on storage.objects for select
to anon, authenticated
using (
  bucket_id in ('avatars', 'checkins', 'community', 'chat-media')
  and (auth.jwt()->>'iss') = 'https://securetoken.google.com/dalattrip-8c1d2'
  and (auth.jwt()->>'aud') = 'dalattrip-8c1d2'
  and nullif(auth.jwt()->>'sub', '') is not null
  and (storage.foldername(name))[1] = (auth.jwt()->>'sub')
);

drop policy if exists "dalattrip firebase users insert own media" on storage.objects;
create policy "dalattrip firebase users insert own media"
on storage.objects for insert
to anon, authenticated
with check (
  bucket_id in ('avatars', 'checkins', 'community', 'chat-media')
  and (auth.jwt()->>'iss') = 'https://securetoken.google.com/dalattrip-8c1d2'
  and (auth.jwt()->>'aud') = 'dalattrip-8c1d2'
  and nullif(auth.jwt()->>'sub', '') is not null
  and (storage.foldername(name))[1] = (auth.jwt()->>'sub')
);

drop policy if exists "dalattrip firebase users update own media" on storage.objects;
create policy "dalattrip firebase users update own media"
on storage.objects for update
to anon, authenticated
using (
  bucket_id in ('avatars', 'checkins', 'community', 'chat-media')
  and (auth.jwt()->>'iss') = 'https://securetoken.google.com/dalattrip-8c1d2'
  and (auth.jwt()->>'aud') = 'dalattrip-8c1d2'
  and nullif(auth.jwt()->>'sub', '') is not null
  and (storage.foldername(name))[1] = (auth.jwt()->>'sub')
)
with check (
  bucket_id in ('avatars', 'checkins', 'community', 'chat-media')
  and (auth.jwt()->>'iss') = 'https://securetoken.google.com/dalattrip-8c1d2'
  and (auth.jwt()->>'aud') = 'dalattrip-8c1d2'
  and nullif(auth.jwt()->>'sub', '') is not null
  and (storage.foldername(name))[1] = (auth.jwt()->>'sub')
);

drop policy if exists "dalattrip firebase users delete own media" on storage.objects;
create policy "dalattrip firebase users delete own media"
on storage.objects for delete
to anon, authenticated
using (
  bucket_id in ('avatars', 'checkins', 'community', 'chat-media')
  and (auth.jwt()->>'iss') = 'https://securetoken.google.com/dalattrip-8c1d2'
  and (auth.jwt()->>'aud') = 'dalattrip-8c1d2'
  and nullif(auth.jwt()->>'sub', '') is not null
  and (storage.foldername(name))[1] = (auth.jwt()->>'sub')
);
