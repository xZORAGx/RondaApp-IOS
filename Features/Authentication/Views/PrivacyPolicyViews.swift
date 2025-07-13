//
//  PrivacyPolicyViews.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 11/7/25.
//

//  RondaApp/Features/Authentication/Views/PrivacyPolicyView.swift

import SwiftUI

struct PrivacyPolicyView: View {
    
    // Esta acción se ejecutará cuando el usuario acepte la política.
    // La usaremos para actualizar el estado en Firestore y cerrar esta vista.
    var onAccept: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            
            Text("Política de Privacidad")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // Usamos un ScrollView para que el texto sea legible en cualquier pantalla.
            ScrollView {
                Text(privacyPolicyText)
                    .font(.body)
                    .padding(.horizontal)
            }
            
            // Botón de Aceptar
            Button(action: onAccept) {
                Text("Aceptar y Continuar")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // El texto de la política de privacidad.
    // Por organización, podría estar en un archivo aparte, pero aquí funciona bien.
    private let privacyPolicyText = """
    Fecha de última actualización: 11 de julio de 2025

    Bienvenido a RondaApp. Tu privacidad es de suma importancia para nosotros. Esta Política de Privacidad explica qué datos recopilamos, cómo los usamos y qué derechos tienes sobre ellos.

    1. Información que Recopilamos
    Para proporcionar y mejorar nuestro servicio, recopilamos los siguientes tipos de información:

    Información proporcionada por el usuario:

    Datos de la cuenta: Al registrarte a través de Google o Apple, recibimos tu nombre, dirección de correo electrónico y un identificador de usuario único. También te pedimos que proporcieres un nombre de usuario público y tu edad para asegurar que cumplas con el requisito de mayoría de edad.

    Contenido generado por el usuario: Esto incluye los nombres de las salas que creas, las descripciones, las bebidas personalizadas, los mensajes enviados en el chat y las fotos que puedas subir para los grupos.

    Información recopilada automáticamente:

    Datos de uso: Recopilamos información sobre cómo interactúas con nuestra aplicación, como las funciones que utilizas, las salas a las que te unes y tu actividad general. Esto se hace a través de servicios de análisis como Firebase Analytics.

    Datos del dispositivo: Podemos recopilar información básica del dispositivo (como el modelo y el sistema operativo) para optimizar el rendimiento y solucionar errores.

    2. Cómo Usamos Tu Información

    Utilizamos la información que recopilamos para los siguientes propósitos:

    Para proporcionar y mantener el servicio: Gestionar tu cuenta, permitirte unirte y crear salas, y operar todas las funcionalidades de la aplicación.

    Para personalizar tu experiencia: Mostrarte tu progreso, tus logros y la actividad relevante de tus amigos.

    Para comunicación: Enviarte notificaciones push (si las habilitas) sobre actividad en tus salas o eventos importantes.

    Para mostrar publicidad: En la versión gratuita de la aplicación, utilizamos Google AdMob para mostrar anuncios relevantes. Este servicio puede recopilar datos para personalizar dichos anuncios.

    Para seguridad y mejoras: Analizar datos de uso para mejorar la estabilidad, el rendimiento y la seguridad de la aplicación.

    3. Cómo Compartimos Tu Información

    No vendemos tu información personal. Solo la compartimos en las siguientes circunstancias:

    Con proveedores de servicios: Utilizamos servicios de terceros como Firebase (Google) para el backend, la autenticación, la base de datos y el almacenamiento. Estos proveedores solo tienen acceso a los datos necesarios para realizar sus funciones.

    Por motivos legales: Podemos divulgar tu información si así lo exige la ley o para proteger los derechos, la propiedad o la seguridad de RondaApp, nuestros usuarios u otros.

    4. Seguridad de los Datos

    Nos tomamos la seguridad muy en serio. Utilizamos las mejores prácticas de la industria y los servicios de seguridad proporcionados por Firebase para proteger tu información contra el acceso no autorizado, la alteración o la destrucción.

    5. Tus Derechos

    Tienes derecho a acceder, corregir o solicitar la eliminación de tus datos personales. Puedes gestionar gran parte de tu información directamente desde la aplicación. Para solicitudes de eliminación de cuenta, por favor, contacta con nosotros.

    6. Privacidad de los Menores

    RondaApp no está dirigida a personas menores de 18 años. No recopilamos de forma intencionada información de menores de edad. Si descubrimos que un menor nos ha proporcionado información personal, la eliminaremos de inmediato.

    7. Cambios en esta Política

    Podemos actualizar nuestra Política de Privacidad de vez en cuando. Te notificaremos de cualquier cambio publicando la nueva política en esta página y, si los cambios son significativos, a través de una notificación en la app.
    """
}

#Preview {
    // Así podemos previsualizar la vista. La acción de aceptar no hará nada en el preview.
    PrivacyPolicyView(onAccept: {})
}
