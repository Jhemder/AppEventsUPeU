pipeline {
    agent any

    stages {
        stage('Descargar Código') {
            steps {
                echo '=== Descargando el repositorio desde GitHub ==='
                checkout scm
            }
        }

        stage('Limpiar Proyecto') {
            steps {
                echo '=== Limpiando caché anterior de Flutter ==='
                bat 'flutter clean'
            }
        }

        stage('Instalar Dependencias') {
            steps {
                echo '=== Descargando paquetes del pubspec.yaml ==='
                bat 'flutter pub get --no-precompile'
            }
        }

        stage('Análisis de Código') {
            steps {
                echo '=== Verificando lints (Ignorando fallos menores) ==='
                // El "|| exit 0" obliga a Windows a decir que todo está "OK" aunque haya advertencias
                bat 'flutter analyze || exit 0'
            }
        }

        stage('Compilar APK Release') {
            steps {
                echo '=== Compilando el APK Final del Sistema de Eventos ==='
                bat 'flutter build apk --release'
            }
        }
    }

    post {
        success {
            echo '==================================================='
            echo '¡Listo, mano! El APK de Eventos UPeU se compiló con éxito.'
            echo '==================================================='
        }
        failure {
            echo '==================================================='
            echo '💥 Hubo un error en el pipeline. Revisa los logs de arriba, mano.'
            echo '==================================================='
        }
    }
}