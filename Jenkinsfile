pipeline {
    agent any

    environment {
        // Esto ayuda a que Flutter no se quede colgado esperando inputs en la consola de Windows
        PUB_ENVIRONMENT = 'jenkins_ci'
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
                bat 'flutter pub get'
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