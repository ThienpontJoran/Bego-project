-- De database van de Bego Netwerkkaart.
-- Gebruik: Supabase > SQL Editor > New query > dit hele bestand plakken > Run.
-- Je hoeft dit maar één keer te doen. Daarna: 2_eigen_gegevens.sql.

-- ---------- Tabellen ----------

create table contacten (
  id            uuid primary key,
  soort         text not null,                -- chirurg, tandarts of labo
  naam          text not null,
  praktijk      text not null default '',
  adres         text not null default '',
  breedtegraad  double precision not null,     -- plek op de kaart
  lengtegraad   double precision not null,
  telefoon      text not null default '',
  email         text not null default '',
  merken        text[] not null default '{}',  -- lijst van implantaatmerken
  interesse     text not null,
  opmerking     text not null default '',
  keten_naam    text not null default '',      -- zelfgekozen naam van de keten (leeg = standaard)
  gemaakt_op    timestamptz not null default now()
);

create table bezoeken (
  id                   uuid primary key,
  -- "on delete cascade": verwijder je een contact, dan verdwijnen zijn bezoeken mee.
  contact_id           uuid not null references contacten (id) on delete cascade,
  datum                timestamptz not null,
  soort                text not null,          -- bezoek, telefoon, email of beurs
  verslag              text not null default '',
  volgende_stap        text not null default '',
  volgende_stap_datum  timestamptz,
  interesse_na         text not null
);

create table relaties (
  id          uuid primary key,
  eerste_id   uuid not null references contacten (id) on delete cascade,
  tweede_id   uuid not null references contacten (id) on delete cascade,
  bevestigd   boolean not null default true,
  opmerking   text not null default '',
  kleur       bigint                           -- kleur van de lijn als getal (leeg = grijs)
);

-- Sneller zoeken op de verwijzingen.
create index on bezoeken (contact_id);
create index on relaties (eerste_id);
create index on relaties (tweede_id);

-- ---------- Beveiliging (Row Level Security) ----------
-- Met RLS aan mag niemand iets, tenzij een regel ("policy") het toelaat.
-- Onze regel: alleen wie ingelogd is ("authenticated") mag lezen en aanpassen.
-- Wie niet ingelogd is (de publishable key alleen) krijgt dus niets te zien.

alter table contacten enable row level security;
alter table bezoeken  enable row level security;
alter table relaties  enable row level security;

create policy "Alleen ingelogde gebruikers" on contacten
  for all to authenticated using (true) with check (true);

create policy "Alleen ingelogde gebruikers" on bezoeken
  for all to authenticated using (true) with check (true);

create policy "Alleen ingelogde gebruikers" on relaties
  for all to authenticated using (true) with check (true);
