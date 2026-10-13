import axios from 'axios';
import { appLogger } from './logger.js';

interface GeocodeResult {
  locationName: string | null;
  county: string | null;
}

/**
 * Reverse geocodes latitude and longitude using Nominatim (OpenStreetMap).
 * Nominatim requires a user-agent header and has a strict rate limit (1 req/sec).
 */
export async function reverseGeocode(lat: number, lng: number): Promise<GeocodeResult> {
  try {
    const response = await axios.get('https://nominatim.openstreetmap.org/reverse', {
      params: {
        lat,
        lon: lng,
        format: 'json',
        zoom: 10, // City/County level
        addressdetails: 1,
      },
      headers: {
        'User-Agent': 'FieldTrack/1.0 (contact@fieldtrack.app)',
      },
      timeout: 5000,
    });

    if (response.data && response.data.address) {
      const address = response.data.address;
      // Nominatim might return county, city, town, village, or state
      const county = address.county || address.state_district || address.state || null;
      
      // We'll use the display_name or a more specific part as the locationName
      let locationName = address.city || address.town || address.village || address.suburb || null;
      if (!locationName && response.data.display_name) {
        // Fallback to the first part of the display name
        locationName = response.data.display_name.split(',')[0].trim();
      }

      return {
        locationName,
        county,
      };
    }
  } catch (error) {
    appLogger.error(`Geocoding failed for ${lat}, ${lng}`, error);
  }

  return { locationName: null, county: null };
}
