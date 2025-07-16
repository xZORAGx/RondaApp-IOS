// Fichero: RondaApp/Core/Services/AdManager.swift
// ✅ VERSIÓN FINAL-FINAL-FINAL-DEFINITIVA

import Foundation
import GoogleMobileAds
import UIKit

class AdManager: NSObject, FullScreenContentDelegate {
    
    private var rewardedAd: RewardedAd?
    private var onRewardEarned: (() -> Void)?

    override init() {
        super.init()
        Task {
            await loadRewardedAd()
        }
    }
    
    func loadRewardedAd() async {
        do {
            // ✅ CORRECCIÓN FINAL: El parámetro es `with:`, no `withAdUnitID:`.
            rewardedAd = try await RewardedAd.load(
                with: "ca-app-pub-3940256099942544/1712485313"
            )
            rewardedAd?.fullScreenContentDelegate = self
        } catch {
            print("Error al cargar el anuncio recompensado: \(error.localizedDescription)")
        }
    }
    
    func showRewardedAd(onRewardEarned: @escaping () -> Void) {
        self.onRewardEarned = onRewardEarned
        
        guard let ad = rewardedAd else {
            print("El anuncio recompensado no estaba listo. Cargando de nuevo.")
            Task { await loadRewardedAd() }
            return
        }
        
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController else {
            print("No se encontró un ViewController para presentar el anuncio.")
            return
        }
        
        ad.present(from: rootViewController) {
            let reward = ad.adReward
            print("Recompensa obtenida: \(reward.amount) \(reward.type)")
            self.onRewardEarned?()
            
            self.rewardedAd = nil
            Task { await self.loadRewardedAd() }
        }
    }
    
    // MARK: - FullScreenContentDelegate
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("El anuncio no se pudo mostrar: \(error.localizedDescription)")
        Task { await loadRewardedAd() }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Anuncio cerrado por el usuario.")
        Task { await self.loadRewardedAd() }
    }
}
