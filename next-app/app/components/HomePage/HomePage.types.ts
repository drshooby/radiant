export interface Montage {
  id: number;
  thumbnail: string;
  title: string;
  url: string;
}

export interface HomePageProps {
  username?: string;
}

export interface VideoPlayerProps {
  videoUrl: string | null;
  loading: boolean;
}