local name = 'bitwarden';
local nginx = '1.24.0';
local version = '1.36.0';
local python = '3.12-slim-bookworm';
local debian = 'bookworm-slim';
local platform = '26.03.1';
local platform_buster = '25.02';
local playwright = 'mcr.microsoft.com/playwright:v1.48.2-jammy';
local deployer = 'https://github.com/syncloud/store/releases/download/4/syncloud-release';
local distro_default = 'bookworm';
local distros = ['bookworm', 'buster'];

local platform_image(distro, arch) =
  'syncloud/platform-' + distro + '-' + arch + ':' + (if distro == 'buster' then platform_buster else platform);

local playwright_env(distro, artifact) = {
  PLAYWRIGHT_FULL_DOMAIN: distro + '.com',
  PLAYWRIGHT_APP_DOMAIN: name + '.' + distro + '.com',
  PLAYWRIGHT_DEVICE_HOST: name + '.' + distro + '.com',
  PLAYWRIGHT_DEVICE_USER: 'user',
  PLAYWRIGHT_DEVICE_PASSWORD: 'Password1',
  PLAYWRIGHT_ARTIFACT_DIR: '/drone/src/artifact/' + artifact,
};

local playwright_step(step_name, artifact, spec) = {
  name: step_name,
  image: playwright,
  environment: playwright_env(distro_default, artifact),
  commands: [
    'apt-get update -qq && apt-get install -y -qq sshpass openssh-client curl',
    'cd test/e2e',
    'npm ci --no-audit --no-fund',
    'npx playwright test --project=desktop ' + spec,
  ],
};

local build(arch, test_ui, dind) = [{
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
      name: 'build',
      image: 'vaultwarden/server:' + version + '-alpine',
      commands: [
        './build.sh',
      ],
    },
    {
      name: 'cli',
      image: 'golang:1.24.0',
      commands: [
        'cd cli',
        'mkdir -p ../build/snap/meta/hooks',
        'CGO_ENABLED=0 go build -buildvcs=false -o ../build/snap/meta/hooks/install ./cmd/install',
        'CGO_ENABLED=0 go build -buildvcs=false -o ../build/snap/meta/hooks/configure ./cmd/configure',
        'CGO_ENABLED=0 go build -buildvcs=false -o ../build/snap/meta/hooks/post-refresh ./cmd/post-refresh',
        'CGO_ENABLED=0 go build -buildvcs=false -o ../build/snap/bin/cli ./cmd/cli',
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
         playwright_step('e2e', 'e2e', 'specs/01-smoke.spec.ts'),
         {
           name: 'test-upgrade-prev',
           image: 'python:' + python,
           commands: [
             'cd test',
             './deps.sh',
             'py.test -x -s upgrade_prev.py --distro=' + distro_default + ' --ver=$DRONE_BUILD_NUMBER --app=' + name,
           ],
         },
         playwright_step('e2e-before-upgrade', 'e2e-before-upgrade', 'specs/02-pre-upgrade.spec.ts'),
         {
           name: 'test-upgrade',
           image: 'python:' + python,
           commands: [
             'cd test',
             './deps.sh',
             'py.test -x -s upgrade.py --distro=' + distro_default + ' --ver=$DRONE_BUILD_NUMBER --app=' + name,
           ],
         },
         playwright_step('e2e-after-upgrade', 'e2e-after-upgrade', 'specs/03-post-upgrade.spec.ts'),
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
    event: ['push', 'pull_request'],
  },
  services: [
    {
      name: 'docker',
      image: 'docker:' + dind,
      privileged: true,
      volumes: [{
        name: 'dockersock',
        path: '/var/run',
      }],
    },
  ] + [
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
    { name: 'dockersock', temp: {} },
  ],
}];

build('amd64', true, '20.10.21-dind') +
build('arm64', false, '19.03.8-dind') +
build('arm', false, '19.03.8-dind')
