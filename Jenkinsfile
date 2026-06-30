pipeline {
    agent any

    environment {
        PUB_ENVIRONMENT = 'jenkins_ci'
        // ¡ESTE ES EL TRUCO! Obliga a Flutter a usar copias en lugar de enlaces simbólicos
        FLUTTER_SUPPRESS_ANALYTICS = 'true'
        GLOBAL_FLUTTER_BUILD_WITH_SYMLINKS = 'false' 
    }

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
                // Forzamos también el parámetro por comando por si acaso
                bat 'flutter pub get --no-precompile'
            }
        }

        stage('Análisis de Código') {
            steps {
                echo '=== Verificando advertencias y lints de la UPeU ==='
                bat 'flutter analyze'
            }
        }

        stage('Correr Pruebas Unitarias') {
            steps {
                echo '=== Ejecutando Tests con Mocktail ==='
                bat 'flutter test'
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