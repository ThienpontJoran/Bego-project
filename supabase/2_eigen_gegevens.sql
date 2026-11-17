-- Stap 2: iedereen ziet alleen zijn EIGEN gegevens.
-- Gebruik: Supabase > SQL Editor > New query > dit hele bestand plakken > Run.
-- (Eerst database.sql, daarna dit bestand. Elk maar één keer.)

-- ---------- 1. Een kolom "eigenaar" bij elke tabel ----------
-- auth.uid() = het id van wie ingelogd is. Voeg je iets toe, dan vult de
-- database zelf de eigenaar in. De app hoeft daar niets voor te doen.

alter table contacten add column eigenaar uuid default auth.uid() references auth.users (id) on delete cascade;
alter table bezoeken  add column eigenaar uuid default auth.uid() references auth.users (id) on delete cascade;
alter table relaties  add column eigenaar uuid default auth.uid() references auth.users (id) on delete cascade;

-- Wat er al in staat, is van de eerste (en voorlopig enige) gebruiker: jij.
update contacten set eigenaar = (select id from auth.users order by created_at limit 1) where eigenaar is null;
update bezoeken  set eigenaar = (select id from auth.users order by created_at limit 1) where eigenaar is null;
update relaties  set eigenaar = (select id from auth.users order by created_at limit 1) where eigenaar is null;

alter table contacten alter column eigenaar set not null;
alter table bezoeken  alter column eigenaar set not null;
alter table relaties  alter column eigenaar set not null;

create index on contacten (eigenaar);
create index on bezoeken (eigenaar);
create index on relaties (eigenaar);

-- ---------- 2. De oude regel ("iedereen die ingelogd is") weg ----------

drop policy "Alleen ingelogde gebruikers" on contacten;
drop policy "Alleen ingelogde gebruikers" on bezoeken;
drop policy "Alleen ingelogde gebruikers" on relaties;

-- ---------- 3. De nieuwe regel: alleen je eigen rijen ----------
-- "using"      = welke rijen je mag zien, aanpassen en verwijderen.
-- "with check" = wat je mag toevoegen of wegschrijven.
-- Bij bezoeken en relaties controleren we ook dat de contacten waarnaar ze
-- verwijzen van jou zijn. Zo kan je niets koppelen aan iemand anders zijn contact.

create policy "Alleen eigen contacten" on contacten
  for all to authenticated
  using (eigenaar = auth.uid())
  with check (eigenaar = auth.uid());

create policy "Alleen eigen bezoeken" on bezoeken
  for all to authenticated
  using (eigenaar = auth.uid())
  with check (
    eigenaar = auth.uid()
    and exists (select 1 from contacten c where c.id = contact_id and c.eigenaar = auth.uid())
  );

create policy "Alleen eigen relaties" on relaties
  for all to authenticated
  using (eigenaar = auth.uid())
  with check (
    eigenaar = auth.uid()
    and exists (select 1 from contacten c where c.id = eerste_id and c.eigenaar = auth.uid())
    and exists (select 1 from contacten c where c.id = tweede_id and c.eigenaar = auth.uid())
  );
