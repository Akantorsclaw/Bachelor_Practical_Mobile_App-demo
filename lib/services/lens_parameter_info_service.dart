class LensParameterInfoService {
  const LensParameterInfoService._();

  static const Map<String, String> _infoByCode = {
    'LC':
        'Lens design refers to how your glasses lenses are shaped and engineered to help you see clearly and comfortably.',
    'MC':
        'Material is what your lenses are made of. Different materials affect weight, thickness, and strength.',
    'PC':
        'Photochromic lenses get darker in sunlight and clear indoors. Polarized options reduce glare from reflective surfaces.',
    'AC':
        'A lens coating is a special layer added to improve performance (for example glare reduction, easier cleaning, and protection).',
    'DVC':
        'Design Variation Code is an additional personalization setting for HOYALUX iD lenses.',
    'MDS':
        'My Design Selection is a personalization output tailored to wearing behavior and visual needs.',
    'SR':
        'Sphere is the main lens power that corrects nearsightedness or farsightedness, measured in diopters (D).',
    'SL':
        'Sphere is the main lens power that corrects nearsightedness or farsightedness, measured in diopters (D).',
    'CR':
        'Cylinder power is the additional correction for astigmatism and improves directional focus.',
    'CL':
        'Cylinder power is the additional correction for astigmatism and improves directional focus.',
    'XR':
        'Axis is the angle (in degrees) used to align astigmatism correction correctly in the lens.',
    'XL':
        'Axis is the angle (in degrees) used to align astigmatism correction correctly in the lens.',
    'AR':
        'Addition power is extra lens strength for near vision, commonly used in progressive lenses.',
    'AL':
        'Addition power is extra lens strength for near vision, commonly used in progressive lenses.',
    'PDR':
        'Pupil Distance is the distance from frame center to the pupil center for the right eye.',
    'PDL':
        'Pupil Distance is the distance from frame center to the pupil center for the left eye.',
    'EPR':
        'Eyepoint height measures vertical pupil position in the frame for accurate lens zone placement.',
    'EPL':
        'Eyepoint height measures vertical pupil position in the frame for accurate lens zone placement.',
    'IR':
        'Inset shifts near-vision zones inward to match natural eye convergence at short viewing distances.',
    'IL':
        'Inset shifts near-vision zones inward to match natural eye convergence at short viewing distances.',
    'RFC':
        'Cornea vertex distance is the gap between the lens and the cornea and impacts effective prescription power.',
    'LFC':
        'Cornea vertex distance is the gap between the lens and the cornea and impacts effective prescription power.',
    'RPA':
        'Pantoscopic angle is the downward tilt of the frame and influences how you look through the lens.',
    'LPA':
        'Pantoscopic angle is the downward tilt of the frame and influences how you look through the lens.',
    'ALR':
        'Axial length is the distance from the front to the back of the eye (right eye).',
    'ALL':
        'Axial length is the distance from the front to the back of the eye (left eye).',
    'FFA':
        'Frame face angle is how much the frame wraps around your face and affects lens positioning.',
    'FL':
        'Frame or Lens Measurement indicates whether values are referenced to frame or lens fitting settings.',
  };

  static String explanationForCode(String code) {
    return _infoByCode[code] ??
        'No additional explanation is available for this parameter.';
  }
}
