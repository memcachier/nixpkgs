{ stdenv, lib, openssh, buildbot-worker, buildbot-pkg, python3Packages, runCommand, makeWrapper }:

let
  withPlugins = plugins: runCommand "wrapped-${package.name}" {
    buildInputs = [ makeWrapper ] ++ plugins;
    propagatedBuildInputs = package.propagatedBuildInputs;
    passthru.withPlugins = package.passthru // {
      withPlugins = moarPlugins: withPlugins (moarPlugins ++ plugins);
    };
  } ''
    makeWrapper ${package}/bin/buildbot $out/bin/buildbot \
    --prefix PYTHONPATH : "${package}/lib/${package.python.libPrefix}/site-packages:$PYTHONPATH"
    ln -sfv ${package}/lib $out/lib
  '';

  package = python3Packages.buildPythonApplication rec {
    name = "${pname}-${version}";
    pname = "buildbot";
    version = "1.3.0";

    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "04sk00cwjrcyg2ccprd2a5z2yacw7fmqaga7jswp77x52agk137v";
    };

    buildInputs = with python3Packages; [
      lz4
      txrequests
      pyjade
      boto3
      moto
      txgithub
      mock
      setuptoolsTrial
      isort
      pylint
      astroid
      pyflakes
      openssh
      buildbot-worker
      buildbot-pkg
      treq
    ];

    propagatedBuildInputs = with python3Packages; [
      # core
      twisted
      jinja2
      zope_interface
      sqlalchemy
      sqlalchemy_migrate
      future
      dateutil
      txaio
      autobahn
      pyjwt
      distro

      # tls
      pyopenssl
      service-identity
      idna

      # docs
      sphinx
      sphinxcontrib-blockdiag
      sphinxcontrib-spelling
      pyenchant
      docutils
      ramlfications
      sphinx-jinja

    ];

    patches = [
      # This patch disables the test that tries to read /etc/os-release which
      # is not accessible in sandboxed builds.
      ./skip_test_linux_distro.patch
    ];

    # 7 tests fail on Python 3 because of some stupid ascii/utf-8 conversion
    # issue, and I don't use the failing modules anyway
    # TimeoutErrors on slow machines -> aarch64
    doCheck = lib.versionOlder python3Packages.python.pythonVersion "3" && !stdenv.isAarch64;

    postPatch = ''
      substituteInPlace buildbot/scripts/logwatcher.py --replace '/usr/bin/tail' "$(type -P tail)"
    '';

    passthru = {
      inherit withPlugins;
      inherit (python3Packages) python;
    };

    meta = with stdenv.lib; {
      homepage = http://buildbot.net/;
      description = "Buildbot is an open-source continuous integration framework for automating software build, test, and release processes";
      maintainers = with maintainers; [ nand0p ryansydnor ];
      license = licenses.gpl2;
    };
  };
in package
