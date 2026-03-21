declare module 'tiged' {
  interface TigedOptions {
    force?: boolean;
    verbose?: boolean;
    cache?: boolean;
    mode?: 'tar' | 'git';
    offlineMode?: boolean;
    'offline-mode'?: boolean;
    disableCache?: boolean;
    'disable-cache'?: boolean;
    subgroup?: boolean;
    'sub-directory'?: string;
  }

  interface TigedInstance {
    clone(dest: string): Promise<void>;
  }

  function tiged(src: string, options?: TigedOptions): TigedInstance;

  export = tiged;
}
