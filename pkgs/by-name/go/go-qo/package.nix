{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "go-qo";
  version = "0.2.7";

  src = fetchFromGitHub {
    owner = "kiki-ki";
    repo = "go-qo";
    rev = "v${version}";
    hash = "sha256-ATvOOx9PXMkxwG39Hn/pBxO4gn/TcAX9QyruD6bLVOI=";
  };

  vendorHash = "sha256-TsDg+OKFCXTsHnDOxmyrXcKUoZsOxJ3XtJ7ITkgllhM=";

  meta = with lib; {
    description = "Interactive minimalist TUI to query JSON, CSV, and TSV using SQL";
    homepage = "https://github.com/kiki-ki/go-qo";
    license = licenses.mit;
    maintainers = with maintainers; [ deftdawg ];
    mainProgram = "qo";
  };
}
