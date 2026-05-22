local name = 'bitwarden';
local nginx = '1.24.0';
local version = '1.36.0';
local python = '3.12-slim-bookworm';
local debian = 'bookworm-slim';
local platform = '26.04.10';
local playwright = 'mcr.microsoft.com/playwright:v1.48.2-jammy';
local deployer = 'https://github.com/syncloud/store/releases/download/4/syncloud-release';
local distro_default = 'bookworm';
local distros = ['bookworm', 'buster'];

local platform_image(distro, arch) =
  'syncloud/platform-' + distro + '-' + arch + ':' + platform;

local build(arch, test_ui) = [{
  kind: 'pipeline',
  type: 'docker',
  name: arch,
  platform: {
    os: 'linux',
    arch: arch,
  },
  steps: [
    {
      name: 'version',
      image: 'debian:' + debian,
      commands: [
        'echo $DRONE_BUILD_NUMBER > version',
      ],
    },
    {
      name: 'nginx',
      image: 'nginx:' + nginx,
      commands: [
        './nginx/build.sh',
      ],
    },
  ] + [
    {
      name: 'nginx test ' + distro,
      image: platform_image(distro, arch),
      commands: [
        './nginx/test.sh',
      ],
    }
    for distro in distros
  ] + [
    {
      name: 'vaultwarden',
      image: 'vaultwarden/server:' + version + '-alpine',
      commands: [
        './vaultwarden/build.sh',
      ],
    },
  ] + [
    {
      name: 'vaultwarden test ' + distro,
      image: platform_image(distro, arch),
      commands: [
        './vaultwarden/test.sh',
      ],
    }
    for distro in distros
  ] + [
    {
      name: 'cli',
      image: 'golang:1.24.0',
      commands: [
        './cli/build.sh',
      ],
    },
    {
      name: 'package',
      image: 'debian:' + debian,
      commands: [
        'VERSION=$(cat version)',
        './package.sh ' + name + ' $VERSION ',
      ],
    },
  ] + [
    {
      name: 'test ' + distro,
      image: 'python:' + python,
      commands: [
        'cd test',
        './deps.sh',
        'py.test -x -s test.py --distro=' + distro + ' --ver=$DRONE_BUILD_NUMBER --app=' + name,
      ],
    }
    for distro in distros
  ] + (if test_ui then [
         {
           name: 'e2e',
           image: playwright,
           environment: {
             PLAYWRIGHT_FULL_DOMAIN: distro_default + '.com',
             PLAYWRIGHT_APP_DOMAIN: name + '.' + distro_default + '.com',
             PLAYWRIGHT_DEVICE_HOST: name + '.' + distro_default + '.com',
             PLAYWRIGHT_DEVICE_USER: 'user',
             PLAYWRIGHT_DEVICE_PASSWORD: 'Password1',
             PLAYWRIGHT_ARTIFACT_DIR: '/drone/src/artifact/e2e',
           },
           commands: [
             './test/e2e/run.sh specs/01-smoke.spec.ts',
           ],
         },
         {
           name: 'test-upgrade-prev',
           image: 'python:' + python,
           commands: [
             'cd test',
             './deps.sh',
             'py.test -x -s upgrade_prev.py --distro=' + distro_default + ' --ver=$DRONE_BUILD_NUMBER --app=' + name,
           ],
         },
         {
           name: 'e2e-before-upgrade',
           image: playwright,
           environment: {
             PLAYWRIGHT_FULL_DOMAIN: distro_default + '.com',
             PLAYWRIGHT_APP_DOMAIN: name + '.' + distro_default + '.com',
             PLAYWRIGHT_DEVICE_HOST: name + '.' + distro_default + '.com',
             PLAYWRIGHT_DEVICE_USER: 'user',
             PLAYWRIGHT_DEVICE_PASSWORD: 'Password1',
             PLAYWRIGHT_ARTIFACT_DIR: '/drone/src/artifact/e2e-before-upgrade',
           },
           commands: [
             './test/e2e/run.sh specs/02-pre-upgrade.spec.ts',
           ],
         },
         {
           name: 'test-upgrade',
           image: 'python:' + python,
           commands: [
             'cd test',
             './deps.sh',
             'py.test -x -s upgrade.py --distro=' + distro_default + ' --ver=$DRONE_BUILD_NUMBER --app=' + name,
           ],
         },
         {
           name: 'e2e-after-upgrade',
           image: playwright,
           environment: {
             PLAYWRIGHT_FULL_DOMAIN: distro_default + '.com',
             PLAYWRIGHT_APP_DOMAIN: name + '.' + distro_default + '.com',
             PLAYWRIGHT_DEVICE_HOST: name + '.' + distro_default + '.com',
             PLAYWRIGHT_DEVICE_USER: 'user',
             PLAYWRIGHT_DEVICE_PASSWORD: 'Password1',
             PLAYWRIGHT_ARTIFACT_DIR: '/drone/src/artifact/e2e-after-upgrade',
           },
           commands: [
             './test/e2e/run.sh specs/03-post-upgrade.spec.ts',
           ],
         },
       ] else []) + [
    {
      name: 'upload',
      image: 'debian:' + debian,
      environment: {
        AWS_ACCESS_KEY_ID: { from_secret: 'AWS_ACCESS_KEY_ID' },
        AWS_SECRET_ACCESS_KEY: { from_secret: 'AWS_SECRET_ACCESS_KEY' },
        SYNCLOUD_TOKEN: { from_secret: 'SYNCLOUD_TOKEN' },
      },
      commands: [
        'PACKAGE=$(cat package.name)',
        'apt update && apt install -y wget',
        'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
        'chmod +x release',
        './release publish -f $PACKAGE -b $DRONE_BRANCH',
      ],
      when: {
        branch: ['stable', 'master'],
        event: ['push'],
      },
    },
    {
      name: 'promote',
      image: 'debian:' + debian,
      environment: {
        AWS_ACCESS_KEY_ID: { from_secret: 'AWS_ACCESS_KEY_ID' },
        AWS_SECRET_ACCESS_KEY: { from_secret: 'AWS_SECRET_ACCESS_KEY' },
        SYNCLOUD_TOKEN: { from_secret: 'SYNCLOUD_TOKEN' },
      },
      commands: [
        'apt update && apt install -y wget',
        'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
        'chmod +x release',
        './release promote -n ' + name + ' -a $(dpkg --print-architecture)',
      ],
      when: {
        branch: ['stable'],
        event: ['push'],
      },
    },
    {
      name: 'artifact',
      image: 'appleboy/drone-scp:1.6.4',
      settings: {
        host: { from_secret: 'artifact_host' },
        username: 'artifact',
        key: { from_secret: 'artifact_key' },
        timeout: '2m',
        command_timeout: '2m',
        target: '/home/artifact/repo/' + name + '/${DRONE_BUILD_NUMBER}-' + arch,
        source: ['artifact/*'],
        strip_components: 1,
      },
      when: {
        status: ['failure', 'success'],
      },
    },
  ],
  trigger: {
    event: ['push'],
  },
  services: [
    {
      name: name + '.' + distro + '.com',
      image: platform_image(distro, arch),
      privileged: true,
      volumes: [
        { name: 'dbus', path: '/var/run/dbus' },
        { name: 'dev', path: '/dev' },
      ],
    }
    for distro in distros
  ],
  volumes: [
    { name: 'dbus', host: { path: '/var/run/dbus' } },
    { name: 'dev', host: { path: '/dev' } },
  ],
}];

build('amd64', true) +
build('arm64', false) +
build('arm', false)
