{ stdenv, buildPythonPackage, fetchPypi, isPy3k
, cairocffi, cssselect2, defusedxml, pillow, tinycss2
, pytestrunner, pytestcov, pytest-flake8, pytest-isort }:

buildPythonPackage rec {
  pname = "CairoSVG";
  version = "1.0.22";

  src = fetchPypi {
    inherit pname version;
    sha256 = "f66e0f3a2711d2e36952bb370fcd45837bfedce2f7882935c46c45c018a21557";
  };

  propagatedBuildInputs = [ cairocffi cssselect2 defusedxml pillow tinycss2 ];

  checkInputs = [ pytestrunner pytestcov pytest-flake8 pytest-isort ];

  meta = with stdenv.lib; {
    homepage = https://cairosvg.org;
    license = licenses.lgpl3;
    description = "SVG converter based on Cairo";
  };
}
