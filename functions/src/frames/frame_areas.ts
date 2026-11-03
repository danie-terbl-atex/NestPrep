/**
 * The metros a frame's groceries search near (photo-frames ADR-0012): a copy
 * of the app's `CheckersArea` — each city centre and its postal code, which
 * Pick n Pay's store lookup insists on. `frame_areas.test.ts` holds it to
 * `checkers_area.dart`.
 */
export interface FrameArea {
  readonly label: string;
  readonly latitude: number;
  readonly longitude: number;
  readonly postalCode: string;
}

export const FRAME_AREAS = {
  capeTown: { label: 'Cape Town', latitude: -33.9249, longitude: 18.4241, postalCode: '8001' },
  johannesburg: {
    label: 'Johannesburg',
    latitude: -26.2041,
    longitude: 28.0473,
    postalCode: '2001',
  },
  pretoria: { label: 'Pretoria', latitude: -25.7479, longitude: 28.2293, postalCode: '0002' },
  durban: { label: 'Durban', latitude: -29.8587, longitude: 31.0218, postalCode: '4001' },
  gqeberha: { label: 'Gqeberha', latitude: -33.9608, longitude: 25.6022, postalCode: '6001' },
  bloemfontein: {
    label: 'Bloemfontein',
    latitude: -29.0852,
    longitude: 26.1596,
    postalCode: '9301',
  },
  eastLondon: { label: 'East London', latitude: -33.0292, longitude: 27.8546, postalCode: '5201' },
} as const satisfies Record<string, FrameArea>;

export type FrameAreaCode = keyof typeof FRAME_AREAS;

export const FRAME_AREA_CODES = Object.keys(FRAME_AREAS) as [FrameAreaCode, ...FrameAreaCode[]];
