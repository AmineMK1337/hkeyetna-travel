-- ============================================================
-- HKEYETNA — Catalog data extension (places + activities + stays + restaurants)
-- ============================================================

ALTER TABLE public.places
  ADD COLUMN IF NOT EXISTS region TEXT,
  ADD COLUMN IF NOT EXISTS price_level INTEGER,
  ADD COLUMN IF NOT EXISTS weather JSONB;

CREATE TABLE IF NOT EXISTS public.experiences (
  id TEXT PRIMARY KEY,
  place_id TEXT REFERENCES public.places(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  region TEXT NOT NULL,
  category TEXT NOT NULL,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('visite', 'repas', 'activité', 'hébergement', 'transport')),
  duration TEXT,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  rating DECIMAL(3,1),
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  image TEXT,
  description TEXT,
  included TEXT[],
  tags TEXT[],
  social_impact_percent INTEGER CHECK (social_impact_percent BETWEEN 0 AND 100),
  artisans_supported INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.accommodations (
  id TEXT PRIMARY KEY,
  place_id TEXT REFERENCES public.places(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  region TEXT NOT NULL,
  accommodation_type TEXT NOT NULL CHECK (accommodation_type IN ('hotel', 'hostel', 'guesthouse', 'riad', 'camp', 'ecolodge', 'aparthotel')),
  stars INTEGER CHECK (stars BETWEEN 1 AND 5),
  price_per_night_min DECIMAL(10,2) NOT NULL CHECK (price_per_night_min >= 0),
  price_per_night_max DECIMAL(10,2) NOT NULL CHECK (price_per_night_max >= price_per_night_min),
  currency TEXT NOT NULL DEFAULT 'TND',
  rating DECIMAL(3,1),
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  address TEXT,
  image TEXT,
  amenities TEXT[],
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.restaurants (
  id TEXT PRIMARY KEY,
  place_id TEXT REFERENCES public.places(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  region TEXT NOT NULL,
  restaurant_type TEXT NOT NULL CHECK (restaurant_type IN ('restaurant', 'street-food', 'cafe', 'tea-room', 'seafood', 'grill', 'pastry')),
  cuisine TEXT NOT NULL,
  specialties TEXT[],
  price_level INTEGER CHECK (price_level BETWEEN 1 AND 4),
  average_ticket DECIMAL(10,2) CHECK (average_ticket >= 0),
  currency TEXT NOT NULL DEFAULT 'TND',
  rating DECIMAL(3,1),
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  address TEXT,
  opening_hours TEXT,
  image TEXT,
  description TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.experiences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accommodations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'experiences' AND policyname = 'Experiences are publicly readable'
  ) THEN
    CREATE POLICY "Experiences are publicly readable"
      ON public.experiences FOR SELECT
      USING (TRUE);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'accommodations' AND policyname = 'Accommodations are publicly readable'
  ) THEN
    CREATE POLICY "Accommodations are publicly readable"
      ON public.accommodations FOR SELECT
      USING (TRUE);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'restaurants' AND policyname = 'Restaurants are publicly readable'
  ) THEN
    CREATE POLICY "Restaurants are publicly readable"
      ON public.restaurants FOR SELECT
      USING (TRUE);
  END IF;
END $$;
