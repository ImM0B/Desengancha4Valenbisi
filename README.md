# Desengancha 4 Valenbisi 🚲

Este script de bash te permite automatizar la extracción de una bici de Valenbisi, la diferencia con la aplicación es que podrás hacerlo desde una consola y a distancia (sin requerir estar cerca de la estación)

## Requisitos

Para obtener este script y los archivos necesarios, puedes clonar este repositorio utilizando el siguiente comando `git clone` en tu terminal:

```bash
git clone https://github.com/ImM0B/GymBookerUPV.git
```

**Permisos de Ejecución**: Dale permisos de ejecución al script `desengancha.sh` utilizando el siguiente comando:

```bash
chmod +x desengancha.sh
```

**Instalar y correr tor**: Para mayor privacidad, este script hace las peticiones a la API de valenbisi usando la red tor:

```bash
sudo apt update
sudo apt install tor
```

```bash
tor & 
```

**Instalar curl y jq**: Necesarios para correr el script:

```
sudo apt install curl jq
```

## Uso

```bash
Uso: ./valenbisi.sh [opciones]
Opciones:
  --help                      Muestra esta ayuda
  mail                        Indica el mail de la cuenta. Ej: valenbisi@gmail.com
  pin                         Indica el pin de la cuenta.  Ej: 123456
  nº estación                 Indica el número de la estación donde está la bici a sacar. Ej: 36
  nº stand                    Indica el stand donde está la bici a sacar. Ej: 5
```


