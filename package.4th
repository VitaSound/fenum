forth-package
    key-value name fenum
    key-value version 0.1.1
    key-value license COPL
    key-value description fenum
    key-value main fenum.4th
    key-value fmix ~> 0.7
    key-value flint ~> 0.2
    key-value fcov ~> 0.3
    \ packages from git
    \ key-list dependencies <package_name> git <http-url> [branch|tag] fenum
    \ key-list dependencies ftest git https://github.com/VitaSound/ftest.git tag 0.1.0
    \ key-list dependencies ftest git https://github.com/VitaSound/ftest.git branch main
    \ packages from theforth.net
    \ key-list dependencies <package_name> <version>
    \ key-list dependencies base64 1.0.0
    \ key-list dependencies f 0.2.4
    \ key-list dependencies ttester 1.2.1
    key-list dependencies f git https://github.com/VitaSound/f tag 0.2.4
    key-list dependencies ttester git https://github.com/VitaSound/ttester tag 1.2.1
end-forth-package
