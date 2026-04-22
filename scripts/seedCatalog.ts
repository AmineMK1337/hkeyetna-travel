import { createClient } from '@supabase/supabase-js';
import { loadEnvConfig } from '@next/env';
import placesData from '../data/places.json';
import experiencesData from '../data/experiences.json';
import accommodationsData from '../data/accommodations.json';
import restaurantsData from '../data/restaurants.json';

loadEnvConfig(process.cwd());

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error(
    'Missing Supabase env vars. Set NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.local.'
  );
}

const supabase = createClient(supabaseUrl, serviceRoleKey);

function normalizeText(input: string) {
  return input
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim();
}

function buildCityToPlaceMap() {
  const map = new Map<string, string>();

  for (const place of placesData) {
    const key = normalizeText(place.city);
    if (!map.has(key)) {
      map.set(key, place.id);
    }
  }

  map.set('nabeul', 'kerkouane');
  map.set('bizerte', 'ichkeul');

  return map;
}

function resolvePlaceIdByCity(city: string, cityToPlace: Map<string, string>) {
  return cityToPlace.get(normalizeText(city)) ?? null;
}

async function upsertTable(tableName: string, payload: unknown[]) {
  const { error } = await supabase.from(tableName).upsert(payload, { onConflict: 'id' });

  if (error) {
    if (error.code === 'PGRST205' || error.code === '42P01') {
      throw new Error(
        `Table '${tableName}' does not exist yet. Run Supabase migrations first (001_initial.sql then 002_catalog_offers.sql).`
      );
    }

    throw new Error(`Seed error for table '${tableName}': ${error.message}`);
  }

  console.log(`Seeded ${payload.length} rows into ${tableName}`);
}

async function seed() {
  const cityToPlace = buildCityToPlaceMap();

  const places = placesData.map((place) => ({
    id: place.id,
    name: place.name,
    city: place.city,
    region: place.region,
    category: place.category,
    description: place.description,
    image: place.image,
    tags: place.tags,
    rating: place.rating,
    price_level: place.priceLevel,
    price_per_night: place.pricePerNight,
    weather: place.weather,
    lat: place.lat,
    lng: place.lng,
  }));

  const experiences = experiencesData.map((experience) => ({
    id: experience.id,
    place_id: resolvePlaceIdByCity(experience.location, cityToPlace),
    name: experience.name,
    city: experience.location,
    region: experience.region,
    category: experience.category,
    activity_type: experience.activityType,
    duration: experience.duration,
    price: experience.price,
    rating: experience.rating,
    lat: experience.lat,
    lng: experience.lng,
    image: experience.image,
    description: experience.description,
    included: experience.included,
    tags: experience.tags,
    social_impact_percent: experience.socialImpactPercent,
    artisans_supported: experience.artisansSupported,
  }));

  const accommodations = accommodationsData.map((accommodation) => ({
    id: accommodation.id,
    place_id: accommodation.placeId,
    name: accommodation.name,
    city: accommodation.city,
    region: accommodation.region,
    accommodation_type: accommodation.accommodationType,
    stars: accommodation.stars,
    price_per_night_min: accommodation.pricePerNightMin,
    price_per_night_max: accommodation.pricePerNightMax,
    currency: accommodation.currency,
    rating: accommodation.rating,
    lat: accommodation.lat,
    lng: accommodation.lng,
    address: accommodation.address,
    image: accommodation.image,
    amenities: accommodation.amenities,
    description: accommodation.description,
  }));

  const restaurants = restaurantsData.map((restaurant) => ({
    id: restaurant.id,
    place_id: restaurant.placeId,
    name: restaurant.name,
    city: restaurant.city,
    region: restaurant.region,
    restaurant_type: restaurant.restaurantType,
    cuisine: restaurant.cuisine,
    specialties: restaurant.specialties,
    price_level: restaurant.priceLevel,
    average_ticket: restaurant.averageTicket,
    currency: restaurant.currency,
    rating: restaurant.rating,
    lat: restaurant.lat,
    lng: restaurant.lng,
    address: restaurant.address,
    opening_hours: restaurant.openingHours,
    image: restaurant.image,
    description: restaurant.description,
    tags: restaurant.tags,
  }));

  await upsertTable('places', places);
  await upsertTable('experiences', experiences);
  await upsertTable('accommodations', accommodations);
  await upsertTable('restaurants', restaurants);

  console.log('Catalog seed completed successfully.');
}

seed().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
