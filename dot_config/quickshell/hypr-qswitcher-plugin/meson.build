project('hypr-qswitcher-plugin', 'cpp',
  version: '0.1',
  default_options: ['buildtype=release'],
  meson_version: '>= 1.1'
)

cpp_compiler = meson.get_compiler('cpp')
if cpp_compiler.has_argument('-std=c++23')
  add_global_arguments('-std=c++23', language: 'cpp')
elif cpp_compiler.has_argument('-std=c++2b')
  add_global_arguments('-std=c++2b', language: 'cpp')
else
  error('Could not configure current C++ compiler with required C++ standard (C++23)')
endif

add_project_arguments(
  [
    '-Wno-narrowing', '-shared', '-fPIC', '--no-gnu-unique'
  ],
  language: 'cpp')

globber = run_command('find', '.', '-path', './build', '-prune', '-o', '-name', '*.cpp', '-print', check: true)
src = globber.stdout().strip().split('\n')

dependencies = [
  dependency('hyprland'),
  dependency('lua'),
  dependency('pixman-1'),
  dependency('libdrm'),
  dependency('pangocairo'),
  dependency('libinput'),
  dependency('libudev'),
  dependency('wayland-server'),
  dependency('xkbcommon'),
]

shared_module('hypr-qswitcher-plugin', src,
  dependencies: dependencies,
  install: false
)
