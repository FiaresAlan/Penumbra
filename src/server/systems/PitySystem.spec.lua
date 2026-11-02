-- Testes no estilo TestEZ. O TestEZ ainda não está instalado no projeto, então este arquivo
-- não roda sozinho: precisaria do pacote TestEZ (via Wally) e de um runner no Studio.
return function()
    local PitySystem = require(script.Parent.PitySystem)

    describe("PitySystem", function()
        it("fica inativo até duas falhas seguidas", function()
            PitySystem.RecordResult("success")
            PitySystem.RecordResult("failure")
            expect(PitySystem.IsActive()).to.equal(false)
            PitySystem.RecordResult("failure")
            expect(PitySystem.IsActive()).to.equal(true)
            expect(PitySystem.GetGuardianSpeedMultiplier()).to.equal(0.9)
        end)

        it("continua ativo em novas falhas e zera no sucesso", function()
            PitySystem.RecordResult("failure")
            expect(PitySystem.IsActive()).to.equal(true)
            PitySystem.RecordResult("success")
            expect(PitySystem.IsActive()).to.equal(false)
            expect(PitySystem.GetGuardianSpeedMultiplier()).to.equal(1)
        end)

        it("ignora expedições abandonadas", function()
            PitySystem.RecordResult("success")
            PitySystem.RecordResult("failure")
            PitySystem.RecordResult("abandoned")
            expect(PitySystem.GetConsecutiveFailures()).to.equal(1)
        end)
    end)
end
