import { frameAvatarPath } from './frame_avatar';
import { frameJpegEndpoint } from './frame_jpeg';
import { FRAME_AVATAR_PER_CREDENTIAL } from './frame_policy';

/** A member's own picture, served only while it is a current member's look (C-0023 rev 18). */
export const getFrameAvatar = frameJpegEndpoint(FRAME_AVATAR_PER_CREDENTIAL, ({ home }, id) =>
  frameAvatarPath(home, id),
);
