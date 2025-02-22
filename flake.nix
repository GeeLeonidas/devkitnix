{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
    imageA64 = pkgs.dockerTools.pullImage {
      imageName = "devkitpro/devkita64";
      imageDigest = "sha256:0222822d6db12279b81264ddd6e13a85bdfde1b97690365cbdb4c350bdab6ea4";
      sha256 = "zXhIkrKredjPapYS+6x8dwWkHUzfd2bshxYSZu0aGoY=";
      finalImageName = "devkitpro/devkita64";
      finalImageTag = "20241023";
    };
    imageARM = pkgs.dockerTools.pullImage {
      imageName = "devkitpro/devkitarm";
      imageDigest = "sha256:44f969ec4f6d63f3818c8926877b805d9f313a42870f8741a14268fc86220325";
      sha256 = "5TrVKzxGFxocFpWrkgT68Cj0Vg6rF798uPHVpDkhv9Y=";
      finalImageName = "devkitpro/devkitarm";
      finalImageTag = "20250102";
    };
    imagePPC = pkgs.dockerTools.pullImage {
      imageName = "devkitpro/devkitppc";
      imageDigest = "sha256:cccaae711c73a7d87b441a1f31ea86ff8be7037e96cb3546bf4647ae08599662";
      sha256 = "sIocIgG84VdTYEHzgltQpALB7xmPCsdmncY683bzibw=";
      finalImageName = "devkitpro/devkitppc";
      finalImageTag = "20250102";
    };
    extractDocker = image:
      pkgs.vmTools.runInLinuxVM (
        pkgs.runCommand "docker-preload-image" {
          memSize = 14 * 1024;
          buildInputs = [
            pkgs.curl
            pkgs.kmod
            pkgs.docker
            pkgs.e2fsprogs
            pkgs.utillinux
          ];
        }
        ''
          modprobe overlay

          # from https://github.com/tianon/cgroupfs-mount/blob/master/cgroupfs-mount
          mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup
          cd /sys/fs/cgroup
          for sys in $(awk '!/^#/ { if ($4 == 1) print $1 }' /proc/cgroups); do
            mkdir -p $sys
            if ! mountpoint -q $sys; then
              if ! mount -n -t cgroup -o $sys cgroup $sys; then
                rmdir $sys || true
              fi
            fi
          done

          dockerd -H tcp://127.0.0.1:5555 -H unix:///var/run/docker.sock &

          until $(curl --output /dev/null --silent --connect-timeout 2 http://127.0.0.1:5555); do
            printf '.'
            sleep 1
          done

          echo load image
          docker load -i ${image}

          echo run image
          docker run ${image.destNameTag} tar -C /opt/devkitpro -c . | tar -xv --no-same-owner -C $out || true

          echo end
          kill %1
        ''
      );
  in {
    packages.x86_64-linux.devkitA64 = pkgs.stdenv.mkDerivation {
      name = "devkitA64";
      src = extractDocker imageA64;
      nativeBuildInputs = [
        pkgs.autoPatchelfHook
      ];
      buildInputs = [
        pkgs.stdenv.cc.cc
        pkgs.ncurses6
        pkgs.zsnes
      ];
      buildPhase = "true";
      installPhase = ''
        mkdir -p $out
        cp -r $src/{devkitA64,libnx,portlibs,tools} $out
        rm -rf $out/pacman
      '';
    };

    packages.x86_64-linux.devkitARM = pkgs.stdenv.mkDerivation {
      name = "devkitARM";
      src = extractDocker imageARM;
      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = [
        pkgs.stdenv.cc.cc
        pkgs.ncurses6
        pkgs.zsnes
      ];
      buildPhase = "true";
      installPhase = ''
        mkdir -p $out
        cp -r $src/{devkitARM,libgba,libnds,libctru,libmirko,liborcus,portlibs,tools} $out
        rm -rf $out/pacman
      '';
    };

    packages.x86_64-linux.devkitPPC = pkgs.stdenv.mkDerivation {
      name = "devkitPPC";
      src = extractDocker imagePPC;
      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = [
        pkgs.stdenv.cc.cc
        pkgs.ncurses6
        pkgs.expat
        pkgs.xz
      ];
      buildPhase = "true";
      installPhase = ''
        mkdir -p $out
        cp -r $src/{devkitPPC,libogc,portlibs,tools,wut} $out
        rm -rf $out/pacman
      '';
    };
  };
}
