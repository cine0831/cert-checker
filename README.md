# cert-checker
check SSL certificate expiration date HTTPS/SMTP

작성자
----
이장재 (cine0831@gmail.com)

간단하게 curl을 사용해서 인증서 만료기간 출력을 할 수 있는 스크립트 입니다.<br>

- requirement
  + openssl 1.0.x 이상
  + curl 7.40 이상 (must enable smtp protocol)


### Usage: ./cert-checker.sh -d [ domain name ] -p [ https or smtp ] -t [local or remote]
| optinon        | explain              |
|----------------|----------------------|
| -d             | domain               |
| -p             | https or smtp        |
| -t             | local or remote      |

